"""Regression tests for the real shell functions and extraction pipeline."""
from pathlib import Path
import sqlite3
import subprocess
import tempfile
import unittest
import zipfile

SOURCE = (Path(__file__).resolve().parents[1] / 'src/ai-dictionary.sh').read_text()
NORMALIZERS = SOURCE[SOURCE.index('normalize_text()'):SOURCE.index('# Book-language detection')]
HELPERS = SOURCE[SOURCE.index('active_reader_epub()'):SOURCE.index('# Current Kobo book + reading position')]
PIPELINE = SOURCE[SOURCE.index('BOOK=""'):SOURCE.index('# Detect book language locally')]


class BookContextTests(unittest.TestCase):
    def shell(self, code):
        return subprocess.run(['sh'], input=code, text=True, capture_output=True, check=True).stdout

    def test_resolver_uses_only_verified_renderer_and_unique_path(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for pid, exe, paths in [
                ('11', '/usr/local/Kobo/adobehost', ['current.epub', 'current.epub']),
                ('12', '/tmp/adobehost', ['wrong.epub']),
            ]:
                proc = root / pid
                (proc / 'fd').mkdir(parents=True)
                (proc / 'exe').symlink_to(exe)
                for i, path in enumerate(paths):
                    (proc / 'fd' / str(i)).symlink_to('/mnt/onboard/' + path)
            base = HELPERS + '\npidof() { echo "11 12"; }\n'
            self.assertEqual(self.shell(base + f'active_reader_epub "{root}"\n'), '/mnt/onboard/current.epub')
            (root / '11/fd/3').symlink_to('/mnt/onboard/previous.epub')
            self.assertEqual(self.shell(base + f'active_reader_epub "{root}" || echo unavailable\n'), 'unavailable\n')
            for fd in (root / '11/fd').iterdir():
                fd.unlink()
            self.assertEqual(self.shell(base + f'active_reader_epub "{root}" || echo unavailable\n'), 'unavailable\n')

    def test_resolver_rejects_unrepresentable_path(self):
        with tempfile.TemporaryDirectory() as folder:
            proc = Path(folder) / '11'
            (proc / 'fd').mkdir(parents=True)
            (proc / 'exe').symlink_to('/usr/local/Kobo/adobehost')
            (proc / 'fd/1').symlink_to('/mnt/onboard/a|b.epub')
            base = HELPERS + '\npidof() { echo 11; }\n'
            self.assertEqual(self.shell(base + f'active_reader_epub "{folder}" || echo unavailable\n'), 'unavailable\n')

    def test_literal_normalized_match(self):
        code = NORMALIZERS + HELPERS + '''
context_contains_selection 'go­rilla' 'A GORILLA waits.' && echo soft-hyphen
context_contains_selection 'two words' 'two
words' && echo whitespace
context_contains_selection '[a.*]' 'literal [a.*] text' && echo literal
context_contains_selection 'missing' 'unrelated text' || echo absent
context_contains_selection '   ' 'any text' || echo empty
'''
        self.assertEqual(self.shell(code).splitlines(), ['soft-hyphen', 'whitespace', 'literal', 'absent', 'empty'])

    def test_fallback_html_cleaner_decodes_numeric_entities(self):
        out = self.shell(NORMALIZERS + "\nprintf '%s' '<p>one&#160;two&#xA0;three&#39;</p>' | clean_epub_html\n")
        self.assertIn("one two three'", out)

    def test_busybox_style_listing_preserves_member_spaces(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            book = root / 'test.epub'
            with zipfile.ZipFile(book, 'w') as archive:
                archive.writestr('Text/chapter one.xhtml', '<p>test</p>')
            unzip = root / 'unzip'
            unzip.write_text('#!/bin/sh\n[ "$1" = "-Z1" ] && exit 1\nexec /usr/bin/unzip "$@"\n')
            unzip.chmod(0o700)
            out = self.shell(HELPERS + f'\nUNZIP="{unzip}"\nlist_epub_paths "{book}"\n')
            self.assertEqual(out, 'Text/chapter one.xhtml\n')

    def pipeline(self, helper_text='The selected term is nectarine.', helper_rc=0,
                 active=True, current_cfi='chapter.xhtml#point(/1/4/2/1:0)',
                 chapter='The selected term is nectarine.', changed=False):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            onboard = root / 'onboard'
            adds = onboard / '.adds'
            (adds / 'ai-tools').mkdir(parents=True)
            current = onboard / "Current reader's book.epub"
            previous = onboard / 'previous.epub'
            for book, text in [(current, chapter), (previous, 'Previous book also contains nectarine.')]:
                with zipfile.ZipFile(book, 'w') as archive:
                    archive.writestr('chapter.xhtml', '<html><body><p>' + text + '</p></body></html>')
            db = root / 'reader.sqlite'
            conn = sqlite3.connect(db)
            conn.execute('create table content(ContentID, Title, Attribution, ChapterIDBookmarked, ContentType, ReadStatus, DateLastRead)')
            # Previous book is newer and "reading"; active book is marked unread.
            conn.executemany('insert into content values(?,?,?,?,?,?,?)', [
                ('file://' + str(previous), 'Previous book', 'Old author', current_cfi, 6, 1, '2099-01-01'),
                ('file://' + str(current), 'Current book', 'Current author', current_cfi, 6, 0, '2000-01-01'),
            ])
            conn.commit()
            conn.close()
            (root / 'helper-output').write_text(helper_text)
            helper = adds / 'ai-tools/kobo-context'
            helper.write_text(f'#!/bin/sh\ncat "{root}/helper-output"\nexit {helper_rc}\n')
            helper.chmod(0o700)
            # Override just the live signal: every other selection/fallback statement
            # comes directly from the production script and uses a real SQLite DB/EPUB.
            signal = str(current) if active else ''
            resolver = f'active_reader_epub() {{ printf "%s" "{signal}"; }}\n'
            if changed:
                resolver = f'''active_reader_epub() {{
if [ -f "{root}/called" ]; then printf '%s' "{previous}"; else touch "{root}/called"; printf '%s' "{current}"; fi
}}\n'''
            pipeline = PIPELINE.replace('/mnt/onboard', str(onboard))
            prefix = f'SQLITE="/usr/bin/sqlite3"\nDB="{db}"\nUNZIP="/usr/bin/unzip"\nTEXT=nectarine\n'
            out = self.shell(NORMALIZERS + HELPERS + resolver + prefix + pipeline + '''
printf 'TITLE=%s\nEPUB=%s\nSOURCE=%s\nCONTEXT=%s\n' "$BOOK_TITLE" "$EPUB" "$CONTEXT_SOURCE" "$BOOK_CONTEXT"
''')
            return out

    def test_live_book_overrides_stale_timestamp_and_read_status(self):
        out = self.pipeline()
        self.assertIn('TITLE=Current book', out)
        self.assertNotIn('Previous book', out)
        self.assertIn('selected text in renderer-identified book', out)

    def test_nonmatching_helper_uses_only_active_book_fallback(self):
        out = self.pipeline(helper_text='A completely unrelated passage.')
        self.assertIn('TITLE=Current book', out)
        self.assertIn('SOURCE=exact occurrence in current chapter', out)
        self.assertNotIn('unrelated passage', out)

    def test_helper_error_does_not_count_as_valid_context(self):
        out = self.pipeline(helper_rc=1)
        self.assertIn('SOURCE=exact occurrence in current chapter', out)

    def test_missing_position_can_search_active_epub(self):
        out = self.pipeline(current_cfi='')
        self.assertIn('TITLE=Current book', out)
        self.assertIn('SOURCE=exact occurrence found in book', out)

    def test_missing_signal_never_reuses_recent_book(self):
        out = self.pipeline(active=False)
        self.assertIn('TITLE=Book not identified', out)
        self.assertIn('CONTEXT=[NO SPECIFIC PASSAGE RETRIEVED FROM THE BOOK]', out)
        self.assertNotIn('Previous book', out)

    def test_missing_term_never_searches_previous_book(self):
        out = self.pipeline(helper_text='Not the selection.', chapter='No selected term here.')
        self.assertIn('TITLE=Current book', out)
        self.assertIn('CONTEXT=[NO SPECIFIC PASSAGE RETRIEVED FROM THE BOOK]', out)

    def test_switch_during_extraction_discards_old_context(self):
        out = self.pipeline(changed=True)
        self.assertIn('TITLE=Book not identified', out)
        self.assertIn('EPUB=\n', out)
        self.assertIn('CONTEXT=[NO SPECIFIC PASSAGE RETRIEVED FROM THE BOOK]', out)


if __name__ == '__main__':
    unittest.main()

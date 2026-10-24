"""Reader-only quotation behavior; the full Gemini context is unchanged."""
import os
from pathlib import Path
import subprocess
import unittest

SOURCE = (Path(__file__).resolve().parents[1] / 'src/ai-dictionary.sh').read_text()
DISPLAY = SOURCE[SOURCE.index('make_display_context()'):SOURCE.index('# Resolve the EPUB')]


class DisplayContextTests(unittest.TestCase):
    def excerpt(self, text, needle):
        return subprocess.run(
            ['sh', '-c', DISPLAY + '\nmake_display_context "$TEXT" "$NEEDLE"'],
            env={**os.environ, 'TEXT': text, 'NEEDLE': needle},
            capture_output=True, text=True, check=True,
        ).stdout.strip()

    def test_only_matching_sentence(self):
        for text, needle, expected in [
            ('Before. The reluctant reader waits. After.', 'reluctant', 'The reluctant reader waits.'),
            ('Dr. Smith was reluctant. Another sentence.', 'reluctant', 'Dr. Smith was reluctant.'),
            ('Before! «Are you reluctant?» Next.', 'reluctant', '«Are you reluctant?»'),
            ('One. Un gorilla aspetta. Fine.', 'go\u00adrilla', 'Un gorilla aspetta.'),
            ('First. El lector está reacio. Después.', 'reacio', 'El lector está reacio.'),
        ]:
            with self.subTest(text=text):
                self.assertEqual(self.excerpt(text, needle), expected)

    def test_unrelated_passage_is_hidden(self):
        self.assertEqual(self.excerpt('No matching sentence.', 'missing'), '')
        self.assertEqual(self.excerpt('Any sentence.', ''), '')

    def test_long_sentence_keeps_selection_and_marks_omissions(self):
        text = 'Before. ' + 'Earlier words ' * 45 + 'reluctant ' + 'later words ' * 60 + '. After.'
        out = self.excerpt(text, 'reluctant')
        self.assertIn('reluctant', out)
        self.assertLessEqual(len(out.encode()), 295)
        self.assertTrue(out.startswith('… ') and out.endswith(' …'))


if __name__ == '__main__':
    unittest.main()

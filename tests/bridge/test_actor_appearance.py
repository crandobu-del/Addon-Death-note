import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'bridge'))
from syndicat_rouge.export_reader import actor, BridgeError


class ActorAppearanceTests(unittest.TestCase):
    def test_optional_fields_survive(self):
        source = dict(id='a', name='A', realm='Forever', raceID=2, classID=1, sex='female')
        self.assertEqual(actor(source), source)

    def test_old_actor_still_valid(self):
        source = dict(id='a', name='A', realm='Forever')
        self.assertEqual(actor(source), source)

    def test_invalid_sex_rejected(self):
        with self.assertRaises(BridgeError):
            actor(dict(id='a', name='A', realm='Forever', sex='guessed'))

    def test_invalid_identifiers_rejected(self):
        for key, value in [('raceID', 0), ('classID', -1), ('classID', True)]:
            with self.subTest(key=key, value=value), self.assertRaises(BridgeError):
                actor(dict(id='a', name='A', realm='Forever', **{key: value}))

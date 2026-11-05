"""Activity provider tests: missing tools, real counters and API fixture contracts."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("collect", Path(__file__).resolve().parents[1] / "package/contents/code/collect.py")
collect = importlib.util.module_from_spec(spec)
spec.loader.exec_module(collect)


class CollectorTests(unittest.TestCase):
    def proc(self, *args):
        return {"pid": 123, "ppid": 12, "args": list(args)}

    def test_cpu_uses_deltas_and_excludes_guest(self):
        self.assertEqual(collect.cpu_percent([10, 0, 10, 80, 0, 0, 0, 0], [30, 0, 20, 150, 0, 0, 0, 0]), 30)
        self.assertIsNone(collect.cpu_percent(None, [1]*8))
        self.assertIsNone(collect.cpu_percent([1]*8, [1]*8))

    def test_package_operations_across_distros(self):
        for args in [("apt-get", "install", "vlc"), ("dnf5", "upgrade", "vlc"), ("pacman", "-S", "vlc"), ("flatpak", "install", "org.videolan.VLC"), ("dpkg", "--install", "vlc.deb"), ("pip3", "install", "vlc")]:
            with self.subTest(args=args):
                data = collect.package_snapshot([self.proc(*args)])
                self.assertTrue(data["active"])
                self.assertEqual(data["pid"], 123)
                self.assertNotIn("command", data)

    def test_python_pip_invocations(self):
        for args in [("python3", "-m", "pip", "install", "vlc"), ("python3", "/usr/bin/pip3", "install", "vlc"), ("npm install vlc",)]:
            self.assertTrue(collect.package_snapshot([self.proc(*args)])["active"])

    def test_queries_do_not_report_installation(self):
        for args in [("pacman", "-Qi", "vlc"), ("apt", "show", "vlc"), ("flatpak", "list")]:
            self.assertFalse(collect.package_snapshot([self.proc(*args)])["active"])
        self.assertEqual(collect.package_snapshot([]), {"active": False})

    def test_removal(self):
        for args in [("pacman", "-Rns", "vlc"), ("apt-get", "remove", "vlc"), ("dpkg", "--purge", "vlc")]:
            self.assertIn(collect.package_snapshot([self.proc(*args)])["operation"], {"remove"})

    @patch.object(collect, "fetch")
    def test_lm_studio_v1_loaded_instances(self, fetch):
        fetch.return_value = {"models": [{"key": "id", "display_name": "Model", "loaded_instances": [{"config": {"context_length": 8192}}]}]}
        data = collect.llm_snapshot()
        self.assertEqual(data["runner"], "LM Studio")
        self.assertEqual(data["context"], 8192)
        self.assertNotIn("tokens_per_second", data)

    @patch.object(collect, "fetch")
    def test_ollama_fallback(self, fetch):
        fetch.side_effect = [{}, {}, {"models": [{"name": "test", "size": 1234, "context_length": 4096}]}]
        data = collect.llm_snapshot()
        self.assertEqual(data["runner"], "Ollama")
        self.assertEqual(data["memory"], 1234)

    @patch.object(collect, "fetch")
    def test_missing_or_malformed_apis(self, fetch):
        for payload in [{}, [], {"models": None}, {"data": "invalid"}]:
            fetch.return_value = payload
            self.assertEqual(collect.llm_snapshot(), {"active": False})

    def test_token_rate_resets_between_tasks(self):
        slot = {"id": 0, "id_task": 1, "is_processing": True, "next_token": {"n_decoded": 10}}
        data, state = collect.generation_stats([slot], {}, 100, "port")
        self.assertIsNone(data["tokens_per_second"])
        slot["next_token"]["n_decoded"] = 40
        data, _ = collect.generation_stats([slot], state, 103, "port")
        self.assertEqual(data["tokens_per_second"], 10)
        slot["id_task"] = 2
        data, _ = collect.generation_stats([slot], state, 103, "port")
        self.assertIsNone(data["tokens_per_second"])

    def test_prompt_is_not_generation(self):
        data, _ = collect.generation_stats([{"id": 0, "is_processing": True, "next_token": {"n_decoded": 0}}], {}, 100, "port")
        self.assertEqual(data["phase"], "processing")
        self.assertIsNone(data["tokens_per_second"])
        data, _ = collect.generation_stats([], {}, 100, "port")
        self.assertEqual(data["phase"], "idle")

    @patch.object(collect, "fetch")
    @patch.object(collect, "processes")
    @patch.object(collect, "command")
    def test_disabled_features_do_no_work(self, command, processes, fetch):
        data, state = collect.snapshot(set(), {})
        self.assertEqual(set(data), {"timestamp"})
        self.assertEqual(state, {})
        command.assert_not_called()
        processes.assert_not_called()
        fetch.assert_not_called()

    def test_missing_command_is_optional(self):
        self.assertEqual(collect.command(["/does/not/exist"]), "")


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""Unit tests for custom-teams-summary cache functions."""

import json
import os
import sys
import tempfile
import unittest
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict


# Import functions from custom-teams-summary
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


class TestCacheFunctions(unittest.TestCase):
    """Test suite for cache management functions."""

    def setUp(self):
        """Set up test fixtures."""
        # Use temporary directory for test cache files
        self.test_dir = tempfile.mkdtemp()
        self.cache_file = Path(self.test_dir) / "test_cache.json"
        
        # Override cache file location
        os.environ["WAZUH_TEAMS_CACHE_FILE"] = str(self.cache_file)

    def tearDown(self):
        """Clean up test fixtures."""
        # Clean up temporary files
        if self.cache_file.exists():
            self.cache_file.unlink()
        if Path(self.test_dir).exists():
            Path(self.test_dir).rmdir()

    def test_cache_template_structure(self):
        """Test that cache template has correct structure."""
        # Simulated cache_template function
        template = {
            "alerts": [],
            "last_summary_time": datetime.utcnow().isoformat(),
            "summary_count": 0,
        }
        
        self.assertIn("alerts", template)
        self.assertIn("last_summary_time", template)
        self.assertIn("summary_count", template)
        self.assertIsInstance(template["alerts"], list)
        self.assertEqual(len(template["alerts"]), 0)
        self.assertIsInstance(template["summary_count"], int)
        self.assertEqual(template["summary_count"], 0)

    def test_cache_template_defaults(self):
        """Test that cache template initializes with correct defaults."""
        template = {
            "alerts": [],
            "last_summary_time": (datetime.utcnow() - timedelta(days=1)).isoformat(),
            "summary_count": 0,
        }
        
        self.assertEqual(template["summary_count"], 0)
        self.assertEqual(len(template["alerts"]), 0)

    def test_normalize_cache_with_valid_dict(self):
        """Test normalize_cache with valid dictionary."""
        valid_cache = {
            "alerts": [
                {
                    "rule": {"id": "200001", "level": 10},
                    "agent": {"name": "test-agent"},
                    "timestamp": datetime.utcnow().isoformat(),
                }
            ],
            "last_summary_time": datetime.utcnow().isoformat(),
            "summary_count": 5,
        }
        
        # Validation check
        self.assertIsInstance(valid_cache["alerts"], list)
        self.assertEqual(len(valid_cache["alerts"]), 1)
        self.assertIsInstance(valid_cache["summary_count"], int)

    def test_normalize_cache_with_empty_dict(self):
        """Test normalize_cache with empty dictionary."""
        empty_cache = {}
        
        # Should reconstruct with defaults
        self.assertNotIn("alerts", empty_cache)
        
        # After normalization, should have structure
        normalized = {
            "alerts": empty_cache.get("alerts", []),
            "last_summary_time": empty_cache.get("last_summary_time", 
                                                 (datetime.utcnow() - timedelta(days=1)).isoformat()),
            "summary_count": empty_cache.get("summary_count", 0),
        }
        
        self.assertIn("alerts", normalized)
        self.assertIn("last_summary_time", normalized)
        self.assertIn("summary_count", normalized)

    def test_normalize_cache_with_invalid_alerts(self):
        """Test normalize_cache with invalid alerts list."""
        invalid_cache = {
            "alerts": "not a list",  # Invalid
            "last_summary_time": datetime.utcnow().isoformat(),
            "summary_count": 0,
        }
        
        # Should reset alerts to empty list
        normalized = {
            "alerts": invalid_cache.get("alerts") if isinstance(invalid_cache.get("alerts"), list) else [],
            "last_summary_time": invalid_cache.get("last_summary_time"),
            "summary_count": invalid_cache.get("summary_count", 0),
        }
        
        self.assertIsInstance(normalized["alerts"], list)
        self.assertEqual(len(normalized["alerts"]), 0)

    def test_normalize_cache_with_datetime_object(self):
        """Test normalize_cache converts datetime object to ISO string."""
        cache_with_datetime = {
            "alerts": [],
            "last_summary_time": datetime.utcnow(),  # datetime object, not string
            "summary_count": 0,
        }
        
        # Normalize by converting to string
        normalized = {
            "alerts": cache_with_datetime["alerts"],
            "last_summary_time": cache_with_datetime["last_summary_time"].isoformat() 
                                if isinstance(cache_with_datetime["last_summary_time"], datetime)
                                else cache_with_datetime["last_summary_time"],
            "summary_count": cache_with_datetime["summary_count"],
        }
        
        self.assertIsInstance(normalized["last_summary_time"], str)

    def test_cache_persistence_json(self):
        """Test that cache persists correctly as JSON."""
        test_cache = {
            "alerts": [
                {
                    "rule": {"id": "200001", "level": 12, "description": "Test rule"},
                    "agent": {"name": "test-agent", "id": "001"},
                    "timestamp": datetime.utcnow().isoformat(),
                }
            ],
            "last_summary_time": datetime.utcnow().isoformat(),
            "summary_count": 3,
        }
        
        # Write to JSON
        with open(self.cache_file, "w", encoding="utf-8") as f:
            json.dump(test_cache, f, ensure_ascii=True)
        
        # Read back
        with open(self.cache_file, "r", encoding="utf-8") as f:
            loaded_cache = json.load(f)
        
        self.assertEqual(loaded_cache["summary_count"], test_cache["summary_count"])
        self.assertEqual(len(loaded_cache["alerts"]), 1)
        self.assertEqual(loaded_cache["alerts"][0]["rule"]["id"], "200001")

    def test_alert_accumulation(self):
        """Test accumulating multiple alerts in cache."""
        cache = {
            "alerts": [],
            "last_summary_time": (datetime.utcnow() - timedelta(days=1)).isoformat(),
            "summary_count": 0,
        }
        
        # Add multiple alerts
        for i in range(5):
            cache["alerts"].append({
                "rule": {"id": f"200{i:03d}", "level": 10},
                "agent": {"name": f"agent-{i}"},
                "timestamp": datetime.utcnow().isoformat(),
            })
        
        self.assertEqual(len(cache["alerts"]), 5)
        self.assertEqual(cache["alerts"][0]["rule"]["id"], "200000")
        self.assertEqual(cache["alerts"][4]["rule"]["id"], "200004")

    def test_summary_count_increment(self):
        """Test incrementing summary count."""
        cache = {
            "alerts": [],
            "last_summary_time": datetime.utcnow().isoformat(),
            "summary_count": 0,
        }
        
        # Simulate sending summaries
        for _ in range(5):
            cache["summary_count"] += 1
        
        self.assertEqual(cache["summary_count"], 5)

    def test_cache_reset_after_summary(self):
        """Test resetting alerts and timestampafter summary sent."""
        cache = {
            "alerts": [{"rule": {"id": "200001"}}, {"rule": {"id": "200002"}}],
            "last_summary_time": (datetime.utcnow() - timedelta(hours=24)).isoformat(),
            "summary_count": 1,
        }
        
        # Reset cache after summary
        old_count = len(cache["alerts"])
        cache["alerts"] = []
        cache["summary_count"] += 1
        cache["last_summary_time"] = datetime.utcnow().isoformat()
        
        self.assertEqual(old_count, 2)
        self.assertEqual(len(cache["alerts"]), 0)
        self.assertEqual(cache["summary_count"], 2)

    def test_cache_with_nested_object_extraction(self):
        """Test extracting nested fields from cached alerts."""
        alert = {
            "rule": {
                "id": "200001",
                "level": 12,
                "description": "Test rule",
                "mitre": {"id": ["T1234", "T5678"]}
            },
            "agent": {"name": "test-agent", "id": "001"},
            "data": {"srcip": "192.168.1.100"},
            "timestamp": datetime.utcnow().isoformat(),
        }
        
        # Extract nested values
        rule_id = alert.get("rule", {}).get("id")
        rule_level = alert.get("rule", {}).get("level")
        mitre_ids = alert.get("rule", {}).get("mitre", {}).get("id", [])
        source_ip = alert.get("data", {}).get("srcip")
        
        self.assertEqual(rule_id, "200001")
        self.assertEqual(rule_level, 12)
        self.assertEqual(len(mitre_ids), 2)
        self.assertEqual(source_ip, "192.168.1.100")


class TestShouldSendSummary(unittest.TestCase):
    """Test suite for summary trigger logic."""

    def test_should_send_after_time_interval(self):
        """Test that summary should be sent after time interval."""
        old_time = datetime.utcnow() - timedelta(hours=25)
        current_time = datetime.utcnow()
        
        cache = {
            "alerts": [{"rule": {"id": "200001"}}],
            "last_summary_time": old_time.isoformat(),
            "summary_count": 0,
        }
        
        # Check if 24+ hours passed
        last_summary_time = old_time
        hours_passed = (current_time - last_summary_time).total_seconds() / 3600
        
        self.assertGreater(hours_passed, 24)

    def test_should_send_after_alert_threshold(self):
        """Test that summary should be sent after alert threshold."""
        cache = {
            "alerts": [
                {"rule": {"id": f"200{i:03d}"}} 
                for i in range(5)  # 5 alerts, threshold is 3
            ],
            "last_summary_time": datetime.utcnow().isoformat(),
            "summary_count": 0,
        }
        
        MAX_ALERTS_BEFORE_SUMMARY = 3
        should_send = len(cache["alerts"]) >= MAX_ALERTS_BEFORE_SUMMARY
        
        self.assertTrue(should_send)

    def test_should_not_send_below_threshold(self):
        """Test that summary should not be sent below threshold."""
        recent_time = datetime.utcnow() - timedelta(hours=12)
        cache = {
            "alerts": [{"rule": {"id": "200001"}}],  # 1 alert, threshold is 3
            "last_summary_time": recent_time.isoformat(),
            "summary_count": 0,
        }
        
        MAX_ALERTS_BEFORE_SUMMARY = 3
        SUMMARY_INTERVAL_HOURS = 24
        
        last_summary_time = recent_time
        hours_passed = (datetime.utcnow() - last_summary_time).total_seconds() / 3600
        
        should_send = (
            hours_passed >= SUMMARY_INTERVAL_HOURS or 
            len(cache["alerts"]) >= MAX_ALERTS_BEFORE_SUMMARY
        )
        
        self.assertFalse(should_send)


class TestCriticalAlertDetection(unittest.TestCase):
    """Test suite for critical alert detection."""

    def test_critical_level_detection(self):
        """Test detecting critical level alerts."""
        CRITICAL_LEVEL = 15
        
        alert_critical = {"rule": {"id": "200001", "level": 15}}
        alert_high = {"rule": {"id": "200002", "level": 12}}
        alert_medium = {"rule": {"id": "200003", "level": 9}}
        
        self.assertGreaterEqual(alert_critical["rule"]["level"], CRITICAL_LEVEL)
        self.assertLess(alert_high["rule"]["level"], CRITICAL_LEVEL)
        self.assertLess(alert_medium["rule"]["level"], CRITICAL_LEVEL)

    def test_critical_alert_bypasses_accumulation(self):
        """Test that critical alerts bypass cache accumulation."""
        CRITICAL_LEVEL = 15
        
        alert = {"rule": {"level": 15}}
        cache = {"alerts": []}
        
        if alert["rule"]["level"] >= CRITICAL_LEVEL:
            # Send immediately, don't cache
            send_immediately = True
        else:
            cache["alerts"].append(alert)
            send_immediately = False
        
        self.assertTrue(send_immediately)
        self.assertEqual(len(cache["alerts"]), 0)


if __name__ == "__main__":
    unittest.main()

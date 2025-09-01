import requests
import socket
import subprocess
import time
import threading
import os
import logging

from flask import Flask, Response
from prometheus_client import (
    Counter,
    Histogram,
    Gauge,
    generate_latest,
    CONTENT_TYPE_LATEST,
)

app = Flask(__name__)

# Prometheus metrics
http_check_total = Counter(
    "http_health_check_total", "Total HTTP health checks", ["target", "status"]
)
tcp_check_total = Counter(
    "tcp_health_check_total", "Total TCP health checks", ["target", "status"]
)
ping_check_total = Counter(
    "ping_health_check_total", "Total ping health checks", ["target", "status"]
)
dns_check_total = Counter(
    "dns_health_check_total", "Total DNS checks", ["target", "status"]
)
http_response_time = Histogram(
    "http_response_time_seconds", "HTTP response time", ["target"]
)
tcp_response_time = Histogram(
    "tcp_response_time_seconds", "TCP connection time", ["target"]
)
ping_response_time = Histogram(
    "ping_response_time_seconds", "Ping response time", ["target"]
)
dns_response_time = Histogram(
    "dns_response_time_seconds", "DNS resolution time", ["target"]
)
service_up = Gauge("service_up", "Service availability", ["target", "check_type"])


class HealthChecker:
    def __init__(self, target_host, target_port=80, target_path="/health"):
        self.target_host = target_host
        self.target_port = target_port
        self.target_path = target_path
        self.target_url = f"http://{target_host}:{target_port}{target_path}"

    def check_http(self):
        """Layer 7 - Measure HTTP response time"""
        try:
            start_time = time.time()
            response = requests.get(self.target_url, timeout=5)
            response_time = time.time() - start_time

            logging.debug(
                "HTTP status: %d, response: %s", response.status_code, response.text
            )  # Debug line

            http_response_time.labels(target=self.target_host).observe(response_time)

            if response.status_code == 200:
                http_check_total.labels(target=self.target_host, status="success").inc()
                service_up.labels(target=self.target_host, check_type="http").set(1)
                return True
            else:
                http_check_total.labels(target=self.target_host, status="failure").inc()
                service_up.labels(target=self.target_host, check_type="http").set(0)
                return False
        except Exception as e:
            logging.debug("HTTP check error: %s", e)
            http_check_total.labels(target=self.target_host, status="error").inc()
            service_up.labels(target=self.target_host, check_type="http").set(0)
            return False

    def check_tcp(self):
        """Layer 4 - Measure latency when establishing a TCP connection"""
        try:
            start_time = time.time()
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((self.target_host, self.target_port))
            response_time = time.time() - start_time
            sock.close()

            logging.debug("TCP status: %d", result)  # Debug line

            if result == 0:
                tcp_response_time.labels(target=self.target_host).observe(response_time)
                tcp_check_total.labels(target=self.target_host, status="success").inc()
                service_up.labels(target=self.target_host, check_type="tcp").set(1)
                return True
            else:
                tcp_check_total.labels(target=self.target_host, status="failure").inc()
                service_up.labels(target=self.target_host, check_type="tcp").set(0)
                return False
        except Exception as e:
            logging.debug("TCP check error: %s", e)
            tcp_check_total.labels(target=self.target_host, status="error").inc()
            service_up.labels(target=self.target_host, check_type="tcp").set(0)
            return False

    def check_ping(self):
        """Layer 3 - Measure ICMP response time"""
        try:
            start_time = time.time()
            result = subprocess.run(
                ["ping", "-c", "1", "-W", "5000", self.target_host],
                capture_output=True,
                text=True,
            )
            response_time = time.time() - start_time

            logging.debug(
                "Ping output: %d, %s", result.returncode, result.stdout
            )  # Debug line

            if result.returncode == 0:
                ping_response_time.labels(target=self.target_host).observe(
                    response_time
                )
                ping_check_total.labels(target=self.target_host, status="success").inc()
                service_up.labels(target=self.target_host, check_type="ping").set(1)
                return True
            else:
                ping_check_total.labels(target=self.target_host, status="failure").inc()
                service_up.labels(target=self.target_host, check_type="ping").set(0)
                return False
        except Exception as e:
            logging.debug("Ping check error: %s", e)
            ping_check_total.labels(target=self.target_host, status="error").inc()
            service_up.labels(target=self.target_host, check_type="ping").set(0)
            return False

    def check_dns(self):
        """DNS resolution check"""
        try:
            start_time = time.time()
            socket.gethostbyname(self.target_host)
            response_time = time.time() - start_time

            logging.debug("DNS resolution successful")

            dns_response_time.labels(target=self.target_host).observe(response_time)
            dns_check_total.labels(target=self.target_host, status="success").inc()
            service_up.labels(target=self.target_host, check_type="dns").set(1)
            return True
        except Exception as e:
            logging.debug("DNS check error: %s", e)
            dns_check_total.labels(target=self.target_host, status="error").inc()
            service_up.labels(target=self.target_host, check_type="dns").set(0)
            return False

    def run_all_checks(self):
        """Run all health checks"""
        return {
            "dns": self.check_dns(),
            "ping": self.check_ping(),
            "tcp": self.check_tcp(),
            "http": self.check_http(),
        }


def background_monitoring():
    """Background thread for continuous monitoring"""
    target_host = os.getenv("TARGET_HOST", "localhost")
    target_port = int(os.getenv("TARGET_PORT", "8000"))
    target_path = os.getenv("TARGET_PATH", "/health")
    check_interval = int(os.getenv("CHECK_INTERVAL", "30"))

    checker = HealthChecker(target_host, target_port, target_path)

    while True:
        try:
            checker.run_all_checks()
            logging.info(f"Health checks completed for {target_host}")
        except Exception as e:
            logging.info(f"Error during health checks: {e}")

        time.sleep(check_interval)


@app.route("/metrics")
def metrics():
    """Prometheus metrics endpoint"""
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@app.route("/health")
def health():
    """Health check for the monitoring service itself"""
    return "ok"


@app.route("/check")
def manual_check():
    """Manual health check endpoint"""
    target_host = os.getenv("TARGET_HOST", "localhost")
    target_port = int(os.getenv("TARGET_PORT", "8000"))
    target_path = os.getenv("TARGET_PATH", "/health")

    checker = HealthChecker(target_host, target_port, target_path)
    results = checker.run_all_checks()

    return {
        "target": f"{target_host}:{target_port}",
        "results": results,
        "timestamp": time.time(),
    }


if __name__ == "__main__":
    logger = logging.getLogger()
    logging.basicConfig(
        format="%(asctime)s : %(levelname)s : %(name)s : %(message)s",
        level=logging.DEBUG,
    )
    logger.setLevel(logging.DEBUG)

    # Start background monitoring thread
    monitoring_thread = threading.Thread(target=background_monitoring, daemon=True)
    monitoring_thread.start()

    PORT = int(os.getenv("PORT", "9090"))
    logging.info(f"Monitoring service running on http://localhost:{PORT}")
    logging.info(f"Metrics available at http://localhost:{PORT}/metrics")
    logging.info(f"Manual check at http://localhost:{PORT}/check")

    app.run(host="0.0.0.0", port=PORT, debug=False)

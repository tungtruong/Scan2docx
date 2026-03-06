import os
from pathlib import Path

DEFAULTS = {
    "NGINX_LIMIT_ZONE_SIZE": "10m",
    "NGINX_CONN_ZONE_SIZE": "10m",
    "NGINX_CLIENT_MAX_BODY_SIZE": "20m",
    "NGINX_RATE_LIMIT_BURST": "20",
    "NGINX_CONN_LIMIT_PER_IP": "30",
    "NGINX_PROXY_CONNECT_TIMEOUT": "5s",
    "NGINX_PROXY_SEND_TIMEOUT": "60s",
    "NGINX_PROXY_READ_TIMEOUT": "60s",
}


def main() -> None:
    base_dir = Path(__file__).resolve().parent
    template_path = base_dir / "default.conf.template"
    output_path = base_dir / "default.conf"

    content = template_path.read_text(encoding="utf-8")

    for key, default in DEFAULTS.items():
        value = os.getenv(key, default)
        content = content.replace("${" + key + "}", value)

    output_path.write_text(content, encoding="utf-8")
    print(f"Generated: {output_path}")


if __name__ == "__main__":
    main()

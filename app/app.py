import os
from flask import Flask, jsonify

app = Flask(__name__)

# Secret is injected at runtime from Azure Key Vault -> k8s Secret -> env var.
# It is NEVER baked into the image or committed to git.
APP_SECRET = os.environ.get("APP_SECRET", "unset")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "unknown")
VERSION = os.environ.get("APP_VERSION", "0.0.0")


@app.route("/")
def index():
    return jsonify(
        service="terraform-ansible-k3s-argocd-azure-devops",
        environment=ENVIRONMENT,
        version=VERSION,
        secret_loaded=APP_SECRET != "unset",
    )


@app.route("/healthz")
def healthz():
    return jsonify(status="ok"), 200


@app.route("/readyz")
def readyz():
    ready = APP_SECRET != "unset"
    return jsonify(ready=ready), (200 if ready else 503)


@app.route("/burn")
def burn():
    x = 0
    for i in range(5_000_000):
        x += i * i
    return jsonify(result=x)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

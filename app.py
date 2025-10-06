from flask import Flask, render_template, jsonify, request, redirect, url_for
import os, json, threading, time, subprocess

app = Flask(__name__)

# Environment password (do NOT hardcode)
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "smarterzop")

def update_data():
    while True:
        print("🔁 Running fetch.sh ...")
        subprocess.run(["bash", "fetch.sh"], check=False)
        print("✅ Data updated successfully")
        time.sleep(60)  # every 1 minute

@app.route("/")
def home():
    def load_json(name):
        try:
            with open(f"output_{name}.json") as f:
                return json.load(f)
        except Exception:
            return {"status": False, "data": []}

    return render_template(
        "index.html",
        live=load_json("live"),
        up=load_json("up"),
        completed=load_json("completed")
    )

@app.route("/watch")
def watch():
    url = request.args.get("url")
    if not url:
        return "Invalid link", 400
    return render_template("watch.html", url=url)

@app.route("/admin", methods=["GET", "POST"])
def admin():
    if request.method == "POST":
        pwd = request.form.get("password")
        if pwd != ADMIN_PASSWORD:
            return render_template("admin.html", error="Invalid password")
        return render_template("admin.html", success=True)
    return render_template("admin.html")

if __name__ == "__main__":
    threading.Thread(target=update_data, daemon=True).start()
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 10000)))

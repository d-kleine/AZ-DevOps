import random
from locust import HttpUser, task, between


class MyUser(HttpUser):
    wait_time = between(3, 5)

    host = "https://flask-sklearn-webserver.azurewebsites.net:443"

    @task(1)
    def hello_world(self):
        self.client.get("https://flask-sklearn-webserver.azurewebsites.net")

    @task(2)
    def predict(self):
        payload = {
            "CHAS": {"0": random.randint(0, 1)},
            "RM": {"0": random.uniform(1.5, 10.0)},
            "TAX": {"0": random.uniform(99.0, 999.0)},
            "PTRATIO": {"0": random.uniform(5.0, 45.0)},
            "B": {"0": random.uniform(10.0, 999.0)},
            "LSTAT": {"0": random.uniform(1.5, 9.9)}
        }
        self.client.post(
            "/predict", json=payload, headers={'Content-Type': 'application/json'})

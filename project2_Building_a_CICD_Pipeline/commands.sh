# DEPLOY APP
az webapp up --name flask-sklearn-webserver --resource-group Azuredevops --sku B1 --logs --runtime "PYTHON:3.9"
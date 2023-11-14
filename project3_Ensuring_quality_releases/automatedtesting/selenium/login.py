# #!/usr/bin/env python
from selenium import webdriver
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.common.by import By

# Start the browser and login with standard_user


def login(user, password):
    print('Starting the browser...')
    # --uncomment when running in Azure DevOps.
    # options = ChromeOptions()
    # options.add_argument("--headless")
    # driver = webdriver.Chrome(options=options)
    driver = webdriver.Chrome()
    print('Browser started successfully. Navigating to the demo page to login.')
    driver.get('https://www.saucedemo.com/')

    print('Logging in...')
    driver.find_element(
        By.CSS_SELECTOR, "input[id='user-name']").send_keys(user)
    driver.find_element(
        By.CSS_SELECTOR, "input[id='password']").send_keys(password)
    driver.find_element(By.ID, "login-button").click()
    print('Login successful! Proceeding with tests.')
    return driver

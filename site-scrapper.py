# Script to validate following:
# The web page is served correctly 
# A date is being
# Check the date is correct
from datetime import date
from datetime import datetime
import re
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.firefox.options import Options as FirefoxOptions
import argparse
import logging
import sys
import kubernetes.client
from kubernetes import client, config


#Logger and log stream management. Copypasted from old project
logger = logging.getLogger(__name__)
console_handler = logging.StreamHandler(sys.stdout)
file_handler = logging.FileHandler("debug.log")
console_handler.setLevel(logging.INFO)
file_handler.setLevel(logging.DEBUG)

console_formatter = logging.Formatter('%(message)s')
file_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

console_handler.setFormatter(console_formatter)
file_handler.setFormatter(file_formatter)

logger.addHandler(console_handler)
logger.addHandler(file_handler)
logger.setLevel(logging.DEBUG) #set root logging level to DEBUG

#Process input ARGS if any
# Construct the argument parser
ap = argparse.ArgumentParser()

# Add the arguments to the parser
ap.add_argument("-u", "--url", default="http://localhost/",
   help="URL to test. default is http://localhost/")
ap.add_argument("-n", "--namespace", default="decoya-assignment",
   help="k8s namespaces to search for corresponding resources. Default is decoya-assignment ")

args = vars(ap.parse_args())


# Selenium framework - Setup Firefox driver
#driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()))
# Setup Firefox driver
options = FirefoxOptions()
options.add_argument("--headless")
driver = webdriver.Firefox(options=options)

# Validates the date is being by checking element by ID and not empty
def checkDatetime(url):
# Get the div element by ID
    try:
        div_element = driver.find_element(By.ID, "date-time")
        logger.debug(f"{div_element.text}")
        
        dateonpage=re.split('Current Date and Time: |, ',div_element.text)[-2]
        # Check for empty only for simplicty. Proper check would be regex
        if not dateonpage:
            raise ValueError('empty string')
        
        #mydate=datetime.strptime(dateonpage, "%m/%d/%Y, %I:%M:%S %p")
        datetocompare=datetime.strptime(dateonpage, "%m/%d/%Y")
        #dateTimeStart=datetime.strptime(dateTimeStart, "%Y-%m-%d %H:%M:%S")
        logger.debug(f"date on page:  {datetocompare}  " )

        if datetocompare.date() == datetime.now().date():
            return True

    except NoSuchElementException:
        logger.error(f"The date-time element does not exist.")
        return False
    except ValueError as e:
        print(e)
        return False

# The the test was created before it turned out that it was not required :(
def checkHostnameifany(url):
    hostnametochek=""
# Get the div element by ID
    try:
        div_element = driver.find_element(By.ID, "machine-name")
        logger.debug(f"{div_element.text}")
        hostnametochek = div_element.text.split(' ')[-1] #for haven sake...
        logger.debug(f"HOST: {hostnametochek}")
    except NoSuchElementException:
        logger.error("The machine-name element does not exist.") 
        return False

    try:      
        if getKubernetespod(hostnametochek) :
            return True
        else:
            return False
    except Exception as e:
        logger.error(f"Error catched: {e}") 
        return False

def getKubernetespod(hostnametochek):
    config.load_kube_config("~/.kube/config")   # I'm using file named "config" in the "~user" directory
    v1 = kubernetes.client.CoreV1Api()
    # v1.list_node() 
     
    mynamespace = args.get("namespace","default")
    logger.debug(f"namespace {mynamespace}")
    
    #Get list of pods in namespace
    pod_list = v1.list_namespaced_pod(namespace=mynamespace,watch=False)
    #Gets properties of running pods
    for pod in pod_list.items:
        logger.debug(f"{pod.metadata.name}\t{pod.status.phase}\t{pod.status.pod_ip}" )                       
        if hostnametochek in pod.metadata.name :
           return True
    return False


if __name__== "__main__":
   # Navigate to the url
    testresult={}
    url = args.get("url")
   #FOR DEBUG ONLY!!!!
   # url='http://192.168.1.107/'
    logger.debug(f"Got URL {url}")
# actual connect 
    driver.get(url)

# Runs test functions in loop by name; Stores results into dict    
    for testfo in (checkDatetime,checkHostnameifany):
        if testfo(url):
            testresult[testfo.__name__]="PASSED" 
        else:
            testresult[testfo.__name__]="FAILED"
        
    # Close the driver - close connection 
    driver.quit()

# Output of validations
    logger.info("Results: ")
#Just to print
    [logger.info(f"{key} : {value}") for key,value in testresult.items()]



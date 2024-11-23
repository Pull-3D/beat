from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import subprocess
import time

# Caminho do ficheiro onde os links serão armazenados
LINKS_FILE = "links.txt"

# Função para ler links existentes do ficheiro
def ler_links_existentes():
    try:
        with open(LINKS_FILE, "r") as f:
            return set(f.read().splitlines())
    except FileNotFoundError:
        return set()

# Função para gravar links no ficheiro
def gravar_links_novos(links):
    with open(LINKS_FILE, "a") as f:
        for link in links:
            f.write(link + "\n")

# Lista de URLs para verificar
urls = [
    "https://www.beatport.com/top-100",
    "https://www.beatport.com/genre/afro-house/89/top-100",
    "https://www.beatport.com/genre/dance-pop/39/top-100",
    "https://www.beatport.com/genre/deep-house/12/top-100",
    "https://www.beatport.com/genre/house/5/top-100",
    "https://www.beatport.com/genre/nu-disco-disco/50/top-100",
    "https://www.beatport.com/genre/tech-house/11/top-100",
    "https://www.beatport.com/genre/funky-house/81/top-100",
]

# Configurações do Selenium com Chromium
chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")

# Iniciar o navegador usando o ChromeDriver
service = Service('/usr/bin/chromedriver')
driver = webdriver.Chrome(service=service, options=chrome_options)

try:
    # Ler links já existentes
    links_existentes = ler_links_existentes()
    novos_links = set()

    for url in urls:
        print(f"Acessando URL: {url}")
        driver.get(url)
        
        # Esperar que os links de track carreguem
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, "//a[contains(@href, '/track/')]")))
        
        # Encontrar todos os links de track
        links = driver.find_elements(By.XPATH, "//a[contains(@href, '/track/')]")
        
        for link in links:
            href = link.get_attribute("href")
            if href and "https://www.beatport.com/track/" in href and href not in links_existentes:
                novos_links.add(href)
        
    # Executar orpheus.py para os links novos e adicionar ao ficheiro
    if novos_links:
        print(f"Novos links encontrados: {len(novos_links)}")
        for novo_link in novos_links:
            print(f"Executando orpheus.py com o link: {novo_link}")
            subprocess.run(["python3", "orpheus.py", novo_link])
        
        # Gravar os novos links no ficheiro
        gravar_links_novos(novos_links)
    else:
        print("Nenhum link novo encontrado.")

finally:
    # Fechar o navegador
    driver.quit()

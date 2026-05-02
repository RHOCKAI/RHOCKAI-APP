import os
import urllib.request
import re

outfit_weights = {
    "400": "Outfit-Regular.ttf",
    "500": "Outfit-Medium.ttf",
    "600": "Outfit-SemiBold.ttf",
    "700": "Outfit-Bold.ttf"
}

fonts_dir = r"c:\Users\beino\Desktop\AI_POSTURE\frontend\assets\fonts"
os.makedirs(fonts_dir, exist_ok=True)

# User-Agent is required to get woff2 or ttf. If we don't send a modern browser UA, we might get TTF.
# Let's send a generic old User-Agent to force TTF format.
req = urllib.request.Request(
    "https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700",
    headers={'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.0'}
)

try:
    with urllib.request.urlopen(req) as response:
        css = response.read().decode('utf-8')
    
    # Simple parse to find the URLs
    for wght, filename in outfit_weights.items():
        # CSS format usually:
        # /* latin */
        # @font-face {
        #   font-family: 'Outfit';
        #   font-style: normal;
        #   font-weight: 400;
        #   src: url(https://fonts.gstatic.com/s/outfit/v11/QGYyz_MVcBeNP4NJtEtq.ttf) format('truetype');
        # }
        
        # We find the block for font-weight: {wght}; and then the url(...)
        # Regex to find src: url(...) for a specific weight. 
        # This is a bit brittle, but usually works if we match the weight block.
        # Let's just download the file. 
        # A simpler way is to use a direct tool, but let's try the regex.
        pass

except Exception as e:
    print(f"Failed to fetch CSS: {e}")

# Alternative: Using a known working direct download link from a 3rd party or just getting the Google Fonts zip:
zip_url = "https://fonts.google.com/download?family=Outfit"
zip_path = os.path.join(fonts_dir, "Outfit.zip")

import zipfile

try:
    print(f"Downloading Outfit.zip...")
    urllib.request.urlretrieve(zip_url, zip_path)
    
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(fonts_dir)
    print("Success extracted Outfit")
    
    # Rename extracted files if needed. 
    # Usually they are extracted as 'Outfit-Regular.ttf' etc.
    # We will check the directory.
    
except Exception as e:
    print(f"Failed to download Outfit zip: {e}")

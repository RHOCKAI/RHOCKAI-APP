import os
import urllib.request

font_urls = {
    "Rajdhani-Medium.ttf": "https://github.com/google/fonts/raw/main/ofl/rajdhani/Rajdhani-Medium.ttf",
    "Rajdhani-SemiBold.ttf": "https://github.com/google/fonts/raw/main/ofl/rajdhani/Rajdhani-SemiBold.ttf",
    "Rajdhani-Bold.ttf": "https://github.com/google/fonts/raw/main/ofl/rajdhani/Rajdhani-Bold.ttf",
    "Outfit-Regular.ttf": "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Regular.ttf",
    "Outfit-Medium.ttf": "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Medium.ttf",
    "Outfit-SemiBold.ttf": "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-SemiBold.ttf",
    "Outfit-Bold.ttf": "https://github.com/google/fonts/raw/main/ofl/outfit/static/Outfit-Bold.ttf"
}

fonts_dir = r"c:\Users\beino\Desktop\AI_POSTURE\frontend\assets\fonts"
os.makedirs(fonts_dir, exist_ok=True)

for name, url in font_urls.items():
    dest = os.path.join(fonts_dir, name)
    try:
        print(f"Downloading {name}...")
        urllib.request.urlretrieve(url, dest)
        print(f"Success: {name}")
    except Exception as e:
        print(f"Failed to download {name}: {e}")

import os
import urllib.request

url = "https://github.com/google/fonts/raw/main/ofl/outfit/Outfit%5Bwght%5D.ttf"
dest = r"c:\Users\beino\Desktop\AI_POSTURE\frontend\assets\fonts\Outfit-Variable.ttf"

try:
    urllib.request.urlretrieve(url, dest)
    print("Success downloading Outfit variable")
except Exception as e:
    print(f"Failed: {e}")

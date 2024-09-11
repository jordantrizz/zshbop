import pyheif
from PIL import Image
import os

def convert_heic_to_jpg(filename):
    try:
        heif_file = pyheif.read(filename)

        image = Image.frombytes(
            heif_file.mode,
            heif_file.size,
            heif_file.data,
            "raw",
            heif_file.mode
        )

        output_name = os.path.splitext(filename)[0] + ".jpg"

        if os.path.exists(output_name):
            print(f"⚠️ Skipping {filename} — JPG already exists.")
        else:
            image.save(output_name, "JPEG")
            print(f"✅ Converted {filename} → {output_name}")

    except Exception as e:
        print(f"❌ Failed to convert {filename}: {e}")

# Loop over all .HEIC files in the current directory
for file in os.listdir("."):
    if file.lower().endswith(".heic"):
        convert_heic_to_jpg(file)

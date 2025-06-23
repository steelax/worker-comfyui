import base64

def encode_image_to_base64(image_path):
    """Encodes an image file into a Base64 string."""
    with open(image_path, 'rb') as image_file:
        encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
    return encoded_string

def decode_base64_to_image(base64_string, output_image_path):
    """Decodes a Base64 string back into an image file."""
    with open(output_image_path, 'wb') as image_file:
        decoded_bytes = base64.b64decode(base64_string)
        image_file.write(decoded_bytes)

# Example usage:

# Encoding
image_path = r'C:\Users\steph\Downloads\superman.png'  # Change to your image path (PNG or JPEG)
encoded_string = encode_image_to_base64(image_path)
print(f"Base64 Encoded String:\n{encoded_string}\n")

# Decoding
output_image_path = r'C:\Users\steph\Downloads\decoded.png'  # Change to desired output path for the decoded image
decode_base64_to_image("base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAIAAAD8GO2jAAAAMklEQVR4nGI5ZdXAQEvARFPTRy0YtWDUglELRi0YtWDUglELRi0YtWDUAioCQAAAAP//E24Bx3jUKuYAAAAASUVORK5CYII=", output_image_path)
print(f"Image saved as {output_image_path}")
import cv2
import sys
import numpy as np

def compare_images(image_path1, image_path2):
    img1 = cv2.imread(image_path1)
    img2 = cv2.imread(image_path2)
    
    # Convert images to grayscale
    gray_img1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
    gray_img2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)

    # Compute Structural Similarity Index (SSIM) between two images
    ssim_score = cv2.compare_ssim(gray_img1, gray_img2)

    return ssim_score

if __name__ == '__main__':
    image_path1 = sys.argv[1]
    image_path2 = sys.argv[2]
    
    similarity_score = compare_images(image_path1, image_path2)
    print(similarity_score)

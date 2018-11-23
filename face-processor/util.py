import os
import sys
import dlib
import argparse
import numpy as np

from PIL import Image


def increase_image(img, k):
    h, w, _ = img.shape
    image_pil = Image.fromarray(img).resize((w * k, h * k), Image.ANTIALIAS)
    return np.array(image_pil)

def make_slice(x_c, y_c, len_x, len_y):
    sly = slice(int(x_c - len_x / 2), int(x_c + len_x / 2))
    slx = slice(int(y_c - len_y / 2), int(y_c + len_y / 2))
    return slx, sly

def make_mask(len_x, len_y):
    len_x, len_y = int(len_x), int(len_y)
    x_c, y_c = len_x / 2, len_y / 2
    sigma_x, sigma_y = len_x / 2.0, len_y / 2.0

    mask = np.zeros((len_y, len_x))
    for x in range(len_x):
        for y in range(len_y):
            mask[y, x] = -((x - x_c) / sigma_x)**2 -((y - y_c) / sigma_y)**2
    return np.exp(mask)

def shape_to_np(shape, dtype="int"):
    coords = np.zeros((68, 2), dtype=dtype)
    for i in range(0, 68):
        coords[i] = (shape.part(i).x, shape.part(i).y)
    return coords


# def process_photo_old_ver(img, detector, predictor):
#     out_image = img.copy()
#     faces = detector(img, 1)

#     if len(faces) == 0:
#         sys.exit(2)

#     for face_rect in faces:
#         shape = predictor(img, face_rect)
#         shape = shape_to_np(shape)
#         mouth = shape[48:68]

#         left,  top = np.min(mouth, axis=0).astype(int)
#         right, bot = np.max(mouth, axis=0).astype(int)
#         padd = int( (bot - top) / 2 )

#         sly, slx = slice(left - padd, right + padd), slice(top - padd, bot + padd)
#         out_image[slx, sly] = img[slx, sly][::-1, :]
    
#     return out_image


def process_photo_gauss(img, detector, predictor):
    out_image = img.copy()

    faces = detector(img, 1)

    for face_rect in faces:
        shape = predictor(img, face_rect)
        shape = shape_to_np(shape)
        mouth = shape[48:68]

        left,  top = np.min(mouth, axis=0).astype(int)
        right, bot = np.max(mouth, axis=0).astype(int)
        padd = int( (bot - top) / 2 )
        
        len_x = right - left + padd * 2
        len_y = bot - top + padd * 2
        mask  = make_mask(len_x, len_y)
        
        sly, slx = slice(left - padd, right + padd), slice(top - padd, bot + padd)
        
        for l in range(3):
            out_image[slx, sly, l] = out_image[slx, sly, l] * (1 - mask) + img[slx,sly, l][::-1, :] * mask
    
    return out_image



def add_big_eye(img, detector, predictor):
    out_image = img.copy()

    faces = detector(img, 1)

    if not faces:
      sys.exit(2)

    for face_rect in faces:
        shape = predictor(img, face_rect)
        shape = shape_to_np(shape)
        eye_points = shape[42:48]

        left,  top = np.min(eye_points, axis=0)
        right, bot = np.max(eye_points, axis=0)
        padd = (bot - top) / 2

        x_c = (left + right) / 2
        y_c = (top + bot) / 2

        len_x = right - left + padd * 2
        len_y = bot - top + padd * 2
        
        slx, sly = make_slice(x_c, y_c, len_x, len_y)
        eye = increase_image(img[slx, sly], 2)

        len_y, len_x, _ = eye.shape
        mask = make_mask(len_x, len_y)

        slx, sly = make_slice(x_c, y_c, len_x, len_y)

        for l in range(3):
            out_image[slx, sly, l] = out_image[slx, sly, l] * (1 - mask) + eye[:, :, l] * mask 
    return out_image


if __name__ == "__main__":  
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", required=True,
        help="path to input image")
    parser.add_argument("-o", "--output", required=True,
        help="path to output image")
    args = parser.parse_args()

    curr_file = os.path.realpath(__file__)
    curr_path = os.path.dirname(curr_file)

    detector = dlib.get_frontal_face_detector()
    predictor = dlib.shape_predictor(curr_path + "/shape_predictor_68.dat")

    img = dlib.load_rgb_image(args.input)

    img = process_photo_gauss(img, detector, predictor)
    img = add_big_eye(img, detector, predictor)

    dlib.save_image(img, args.output)




import os
import sys
import dlib
import argparse
import numpy as np


def shape_to_np(shape, dtype="int"):
    coords = np.zeros((68, 2), dtype=dtype)
    for i in range(0, 68):
        coords[i] = (shape.part(i).x, shape.part(i).y)
    # return the list of (x, y) - coordinates
    return coords


def process_photo(in_file, out_file, detector, predictor):
    img = dlib.load_rgb_image(in_file)
    out_image = img.copy()

    faces = detector(img, 1)

    if len(faces) == 0:
      sys.exit(2)

    for face_rect in faces:
        shape = predictor(img, face_rect)
        shape = shape_to_np(shape)
        mouth = shape[48:68]

        left,  top = np.min(mouth, axis=0)
        right, bot = np.max(mouth, axis=0)
        padd = (bot - top) / 2

        sly, slx = slice(left - padd, right + padd), slice(top - padd, bot + padd)
        out_image[slx, sly] = img[slx,sly][::-1, :]
    
    dlib.save_image(out_image, out_file)
    return out_image


def process_photo2(in_file, out_file, detector, predictor):
    img = dlib.load_rgb_image(in_file)
    out_image = img.copy()

    faces = detector(img, 1)

    for face_rect in faces:
        shape = predictor(img, face_rect)
        shape = shape_to_np(shape)
        mouth = shape[48:68]

        left,  top = np.min(mouth, axis=0)
        right, bot = np.max(mouth, axis=0)
        padd = (bot - top) // 2
        
        len_x = right - left + padd * 2
        len_y = bot - top + padd * 2
        x_c, y_c = len_x / 2, len_y / 2
        sigma_x, sigma_y = len_x / 2.0, len_y / 2.0
        
        mask = np.zeros((len_y, len_x))
        for x in range(len_x):
            for y in range(len_y):
                mask[y, x] = -((x - x_c) / sigma_x)**2 -((y - y_c) / sigma_y)**2
        mask = np.exp(mask)

        sly, slx = slice(left - padd, right + padd), slice(top - padd, bot + padd)
        
        for l in range(3):
            out_image[slx, sly, l] = out_image[slx, sly, l] * (1 - mask) + img[slx,sly, l][::-1, :] * mask
    
    dlib.save_image(out_image, out_file)
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

  process_photo2(args.input, args.output, detector, predictor)



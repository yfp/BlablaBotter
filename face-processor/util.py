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

	process_photo(args.input, args.output, detector, predictor)



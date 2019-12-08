Title: Deep learning segmentation of Primary Sjögren’s syndrome affected salivary glands from ultrasonography images

Authors: Arso M.Vukicevic*, Milos Radovic*, Alen Zabotti, Vera Milic, Alojzija Hocevar, Orazio De Lucia, Salvatore De Vita, Nenad Filipovic

*Authors equally contributed to this work.

Instructions for running the inference script (inference.py is applied for all four developed models):

	python inference.py --mode=test   # inference for test images
	
	python inference.py --mode=video  # inference for test video
	
	python inference.py --mode=stream # inference for live camera


Folder "FCN-DenseNet" provides OOP inference (class DeepSGUS) for the best-performing algorihtm, with examples (DeepSGUS - sample.py) how to use it in your own implementation.  

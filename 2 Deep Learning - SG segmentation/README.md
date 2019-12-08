Title: Deep SGUS: Deep learning segmentation of Primary Sjögren’s syndrome affected salivary glands from ultrasonography images

Authors Arso M. Vukicevic*,1,2, Milos Radovic*,2,3, Alen Zabotti4, Vera Milic5, Alojzija Hocevar6, Sara Zandonella Callegher4, Orazio De Lucia7, Salvatore De Vita4, Nenad Filipovic1,2

*Corresponding authors {arso_kg@yahoo.com, mradovic@kg.ac.rs} equally contributed to this work

1. Faculty of Engineering, University of Kragujevac, Sestre Janjic 6, Kragujevac, Serbia
2. BioIRC R&D center, Prvoslava Stojanovica 6, Kragujevac, Serbia
3. Everseen, Milutina milankovica 1z, Belgrade, Serbia
4. Azienda Ospedaliero Universitaria, Santa Maria Della Misericordia di Udine, Udine, Italy
5. Institute of Rheumatology, School of Medicine, University of Belgrade, Serbia
6. Department of Rheumatology, Ljubljana University Medical Centre, Ljubljana, Slovenia
7. Department of Rheumatology, ASST Centro Traumatologico Ortopedico G. Pini-CTO, Milano, Italy


Folder "FCN-DenseNet inference"

  Provides OOP inference (class DeepSGUS.py) for the best-performing algorihtm.
  Run script with examples (DeepSGUS - sample.py) to figure out how to use it in your own implementation.  


Folder "Inference all four (FCN, FCN-DenseNet, U-Net, LinkNet) models" 

Instructions for running the inference script (inference.py is applied for all four developed models):

	python inference.py --mode=test   # inference for test images
	
	python inference.py --mode=video  # inference for test video
	
	python inference.py --mode=stream # inference for live camera

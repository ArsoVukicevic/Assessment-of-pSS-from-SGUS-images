# Radiomics-based assessment of Primary Sjogren's Syndrome from salivary gland ultrasonography images

Arso M Vukicevic, Vera Milic, Alen Zabotti, Alojzija Hocevar, Orazio Di Lucia, Georgios Filippou, Salvatore De Vita, Alejandro F Frangi, Athanasios Tzioufas, Nenad Filipovic (2019) Radiomics-based assessment of Primary Sjogren's Syndrome from salivary gland ultrasonography images, doi: 10.1109/JBHI.2019.2923773

https://ieeexplore.ieee.org/abstract/document/8765825


Salivary gland ultrasonography (SGUS) has shown good potential in the diagnosis of Primary Sjögren’s syndrome (pSS). However, a series of international studies have reported needs for improvements of the existing pSS scoring procedures in terms of inter/intra observer reliability before being established as standardized diagnostic tools. The present study aims to solve this problem by employing radiomics features and artificial intelligence (AI) algorithms to make the pSS scoring more objective and faster compared to human expert scoring. The assessment of AI algorithms was performed on a two-centric cohort, which included 600 SGUS images (150 patients) annotated using the original SGUS scoring system proposed in 1992 for pSS. For each image, we extracted 907 histogram-based and descriptive statistics features from segmented salivary glands (SG). 

![](Figure%2001.jpg)

Optimal feature subsets were found using the Genetic algorithm-based wrapper approach. 

![](Figure%2002.jpg)


Among the considered algorithms (7 classifiers and 5 regressors), the best preforming was the Multilayer perceptron (MLP) classifier (κ = 0.7). The MLP over-performed average score achieved by the clinicians (κ = 0.67) by the considerable margin, while its reliability was on the level of human intra-observer variability (κ = 0.71). 

![](Figure%2004.jpg)

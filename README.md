# Computer-Science-Assignment
This is the code for the assignment for the course Computer Science for Business Analytics. In this assignment duplicate detection with LSH as pre-selection is performed on a datasets of TV web pages. 
## Parts of the code
1) The data is imported from a JSON-file.
2) The data in the variable title is cleaned (set to lower cases and normalizing frequently used words for inch and hertz).
3) The model words, as is decscribed in the paper, are extracted and used to make binary vectors each representing a product.
4) Min-hashing using hashfunctions is performed to create a signature matrix. It reduces sparsity of the binary vector without too much losing information.
5) For all possible combinantions of rows and bands, where rows times bands must be the size of the signature matrix, different buckets are formed. With 5 bootstraps of 60% of the data the pair quality, pair completeness and the F1* measure are calculated
6) The combination of rows and bands that produces the highest value for the F1* measure is run on the complete dataset obtaining candidate duplicates, completing the part where LSH is used as pre-selection method
7) The dissimilarity matrix is composed. In this matrix the distance between pairs that are not candidate duplicates will be set to 99999, the distance between pairs with different completelt different values for brand will be set to 99999 and pairs of product that are from the same webshop will be set to 99999. For all other pairs, the cosine distance between the binary vectors of 3) are computed. 
8) A classification algorithm is performed where pairs are set to be duplicates if their distance is lower than a certain threshold.  The gridsearch over threshold values ranging from 0.1 to 1 and 5 bootstraps of 60% the data are used to calculate the F1-measure.

The code is made together with Ilse Den Heeten.

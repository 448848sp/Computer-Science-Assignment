# Computer-Science-Assignment
This is the code for the assignment for the course Computer Science for Business Analytics. In this assignment duplicate detection with LSH as pre-selection is performed on a datasets of TV web pages. 
## Parts of the code
1) the data is imported from a JSON-file.
2)the data in the variable title is cleaned.
3)the model words as is decscribed in the paper are extracted and used to make binary vectors each representing a product.
4) min-hashing using hashfunctions is performed to create a signature matrix. It reduces sparsity of the binary vector without too much losing information.
5)for all possible combinantions of rows and bands, where rows times bands must be the size of the signature matrix, the different buckets are formed. With bootstraps of 60% of the data the pair quality, pair completeness and the F1* measure are calculated
6) The combination of rows and bands that produces the highest value for the F1* measure is run on the complete dataset obtaining candidate duplicates, completing the part where LSH is used as pre-selection method
7) The dissimilarity matrix is composed. In this matrix the distance between pairs that are not candidate duplicates will be set to 99999, pairs with different brands will be set to 99999 and pairs of product that are from the same webshop will be set to 99999
8) A gridsearch over threshold values and bootstrapping of 60% the data 

The code is made together with Ilse Den Heeten

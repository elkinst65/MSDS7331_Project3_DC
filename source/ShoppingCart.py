# -*- coding: utf-8 -*-
"""
Created on Sat Dec 31 17:36:44 2016

@author: BenBrock
"""

from collections import OrderedDict
from itertools import izip, repeat

# generic imports
import pandas as pd
import numpy as np
import csv

debug_flag = False

# getInventoryGoodTypeDictionary

class ShoppingCart (object):
    
    def __init__(self, df, inventory_good_type_dictionary, customer_goods_headers):
        
        self.__dc = df
        self.__inv_good_type_dictionary = inventory_good_type_dictionary
        self.__customer_goods_header = customer_goods_headers
        self.__ARM_FEATURES = self.__dc[customer_goods_headers]       
        self.__ARM_SHOPPING_CART = None
        self.__updated_list = None
        
        # create the feature list of the customer list of header's and convert to 
        # newly reference numbers listed in the database
        self.setFrameByFeatureList(self.__customer_goods_header)
        
        # make a copy of the newly created features based on the original features
        # in the new Shopping Cart DataFrame
        self.getConvertedCustomHeaders()
        
        # write the Shopping Cart DataFrame to the csv excel file type
        self.writeTotalListOfGoodsInInventoryFile()
        
    def setFrameByFeature(self, name):
        
        updated_name = "UPDATED_" + name
        
        self.__ARM_FEATURES.loc[:, updated_name] = 0
        
        
    def setFrameByFeatureList(self, feature_list):
        
        self.__updated_list = []
        
        for name in feature_list:
            
            updated_name = "UPDATED_" + name
            self.__updated_list.append(updated_name)
            
            if debug_flag is True:
                print "NAME ==> {} ".format(name)
                print self.__inv_good_type_dictionary[name]
                print
            
            self.setFrameByFeature(name)
            
            self.convertInventoryValuesGoodTypes(name, updated_name)
            
        return self.__updated_list
        
        
    def getDataFrameInfo(self):
        return self.__dc.info()

    def getDataFrame(self):
        return self.__dc
        
    def getARMDataFrameByFeature(self, name):
        return self.__ARM_FEATURES[name]
        
    def getCustomerGoodTypeHeaders(self):
        return self.__customer_goods_header
        
    def getARMDataFrameInfo(self):
        return self.__ARM_FEATURES.info()

    def getARMDataFrame(self):
        return self.__ARM_FEATURES
        
    def getARMDataFrameNameList(self, name_list):
        return self.__ARM_FEATURES[[name_list]]
        
    def getARMShoppingCartDataFrameInfo(self):
        return self.__ARM_SHOPPING_CART.info()

    def getARMShoppingCartDataFrame(self):
        return self.__ARM_SHOPPING_CART
        
        
    def getInventoryGoodTypeDictionary(self):
        return self.__inv_good_type_dictionary
        
    def getInventoryGoodType(self, name):
        return self.__inv_good_type_dictionary[name]
        
    def getInventoryGoodTypeInputList(self, name):
        return self.__inv_good_type_dictionary[name]['input_list']
        
    def getInventoryGoodTypeOutputList(self, name):
        return self.__inv_good_type_dictionary[name]['output_list']
        
    def convertInventoryValuesGoodTypes(self, name, updated_name):
        
        output_list = self.getInventoryGoodTypeOutputList(name)
        input_list =  self.getInventoryGoodTypeInputList(name)  

        count = 0
        for number in output_list:
            
            if debug_flag is True:
                print (number)
                print (output_list[count])
                print (input_list[count])
                
            self.__ARM_FEATURES.loc[self.__dc[name] == input_list[count], updated_name] = output_list[count]
            count += 1
       
    def getConvertedCustomHeaders(self):
        self.__ARM_SHOPPING_CART = self.__ARM_FEATURES[self.__updated_list] 
        
        return self.__ARM_SHOPPING_CART
        
    def getSortConvertedCustomHeaders(self):

        return self.__ARM_SHOPPING_CART.sort_index()
        
        
    '''  
    Per the ARM design spec, the 1st shopping card ID entry should start at 1 NOT 0.  Therefore, our we must  
    incremented the DataFrame to start at 1 versus 0 (see reference 2).  Additionally, we should sort all of the entries
    in each row in ascending order (low to high values).   We only need the values, not the headers;
    that is why the "header" == False (se reference 1). By doing this, the headers will not be written to the file.
    The ARM Shopping Cart DataFrame will be written to a CSV file using a nifty DataFrame.to_csv()
    method.  This saved a lot of time.   Neat trick that I found by Googling for this.
          
    http://stackoverflow.com/questions/36490263/remove-header-and-footer-from-pandas-dataframe-print
    http://stackoverflow.com/questions/32249960/in-python-pandas-start-row-index-from-1-instead-of-zero-without-creating-additi/32249984#32249984
    '''
    def writeTotalListOfGoodsInInventoryFile(self):
        
        self.__ARM_SHOPPING_CART.index = self.__ARM_SHOPPING_CART.index + 1
        self.__ARM_SHOPPING_CART.sort_index().to_csv('data/dc_crime/DC_Crime_Transaction_Final.csv', header=False)
        
        

def main():
    
    
    # Read in the crime data from the CSV file
    df = pd.read_csv('data/dc_crime/DC_Crime_2015_Lab2_Weather.csv')
    
    input_inv_goods_dict = {'SHIFT_Code': {'output_list': [9, 10, 11], 
                               'list_length': 3, 
                               'name': 'SHIFT_Code', 
                               'input_list': [1, 2, 3]
                               }, 
                 'CRIME_TYPE': {'output_list': [15, 16], 
                               'list_length': 2, 
                               'name': 'CRIME_TYPE', 
                               'input_list': [1, 2]
                               }, 
                'OFFENSE_Code': {'output_list': [0, 1, 2, 3, 4, 5, 6, 7, 8], 
                               'list_length': 9, 
                               'name': 'OFFENSE_Code', 
                               'input_list': [1, 2, 3, 4, 5, 6, 7, 8, 9]
                               },
                'METHOD_Code': {'output_list': [12, 13, 14], 
                                'list_length': 3, 
                                'name': 'METHOD_Code', 
                                'input_list': [1, 2, 3]
                                }, 
                'DistrictID': {'output_list': [17, 18, 19, 20, 21, 22, 23], 
                               'list_length': 7, 
                               'name': 'DistrictID', 
                               'input_list': [1, 2, 3, 4, 5, 6, 7]
                               }, 
                'ANC': {'output_list': [88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127], 
                        'list_length': 40, 
                        'name': 'ANC', 
                        'input_list': [11, 12, 13, 14, 21, 22, 23, 24, 25, 26, 32, 33, 34, 35, 36, 37, 41, 42, 43, 44, 51, 52, 53, 54, 55, 61, 62, 63, 64, 65, 72, 73, 74, 75, 76, 81, 82, 83, 84, 85]
                        }, 
                'PSA_ID': {'output_list': [24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79], 
                           'list_length': 56, 
                           'name': 'PSA_ID', 
                           'input_list': [101, 102, 103, 104, 105, 106, 107, 108, 201, 202, 203, 204, 205, 206, 207, 208, 301, 302, 303, 304, 305, 306, 307, 308, 401, 402, 403, 404, 405, 406, 407, 408, 409, 501, 502, 503, 504, 505, 506, 507, 601, 602, 603, 604, 605, 606, 607, 608, 701, 702, 703, 704, 705, 706, 707, 708]
                           }, 
                'WARD': {'output_list': [80, 81, 82, 83, 84, 85, 86, 87], 
                        'list_length': 8, 
                        'name': 'WARD', 
                        'input_list': [1, 2, 3, 4, 5, 6, 7, 8]
                        }
                }
                
                
    my_customer_goods_test_headers = [ 'OFFENSE_Code',
                        'SHIFT_Code',
                        'METHOD_Code',
                        'CRIME_TYPE',
                        'DistrictID',
                        'PSA_ID',
                        'WARD',
                        'ANC']
                        
    
    
    sc = ShoppingCart(df, input_inv_goods_dict, my_customer_goods_test_headers) 
    
#    print "\nDATA FRAME OUTPUT\n"
#    print sc.getDataFrame()
#    
    print "\nDATA FRAME INPUT\n"
    sc.getDataFrameInfo()
    
    print "\nDATA FRAME INPUT\n"
    sc.getARMDataFrameInfo()
    
#    name = 'WARD'
#    sc.setFrameByFeature(name)
        
#    sc.setFrameByFeatureList(my_customer_goods_test_headers)
    
#    print "\nDATA FRAME INPUT\n"
#    sc.getARMDataFrameInfo()
    
    '''
    import sys
    sys.exit(5)
    
    name = 'WARD'
    updated_name = 'UPDATED_WARD'
    
    print sc.convertInventoryValuesGoodTypes(name, updated_name)
    '''
    
    #temp_list =  'WARD', 'UPDATED_WARD'
    #sc.getARMDataFrameNameList('WARD', 'UPDATED_WARD')
    
    print sc.getARMDataFrame()
    
    sc.getConvertedCustomHeaders()
    
    sc.getARMShoppingCartDataFrameInfo()
    print sc.getARMShoppingCartDataFrame()
    
    print sc.getARMShoppingCartDataFrame().sort_index()
    
    print "\nTEST PRINTING PAGE 158 Python for Finance"
    print "1 ", sc.getARMShoppingCartDataFrame().sort_index()[:6]
    
    print sc.getARMShoppingCartDataFrame().sort_index()[:0]['UPDATED_OFFENSE_Code']
    print sc.getARMShoppingCartDataFrame().sort_index()[:1]['UPDATED_OFFENSE_Code']
    print sc.getARMShoppingCartDataFrame().sort_index()[:2]['UPDATED_OFFENSE_Code']
    print sc.getARMShoppingCartDataFrame().sort_index()[:3]['UPDATED_OFFENSE_Code']
    print sc.getARMShoppingCartDataFrame().sort_index()[:3]['UPDATED_OFFENSE_Code'][0]
    print sc.getARMShoppingCartDataFrame().sort_index()[:3]['UPDATED_OFFENSE_Code'][1]
    
    
    '''            
    http://stackoverflow.com/questions/36490263/remove-header-and-footer-from-pandas-dataframe-print
    http://stackoverflow.com/questions/32249960/in-python-pandas-start-row-index-from-1-instead-of-zero-without-creating-additi/32249984#32249984
    '''
#    sc.getARMShoppingCartDataFrame().index = sc.getARMShoppingCartDataFrame().index + 1
#    sc.getARMShoppingCartDataFrame().sort_index().to_csv('data/dc_crime/DC_Crime_Transaction.csv', header=False)
    
    sc.writeTotalListOfGoodsInInventoryFile()
    
    import sys
    sys.exit(5)
    
    print "\nINPUT GOODS TYPE DICTIONARY\n"
    print sc.getInventoryGoodTypeDictionary()['WARD']
    
    for name in sc.getCustomerGoodTypeHeaders():
        
        print "\n"
        print sc.getInventoryGoodTypeDictionary()[name]['name']
        print sc.getInventoryGoodTypeDictionary()[name]
        
    
    print "\nGET INVENTORY GOOD TYPE"
    print sc.getInventoryGoodType('WARD')
    print sc.getInventoryGoodTypeInputList('WARD')
    print sc.getInventoryGoodTypeOutputList('WARD')
    
    name = 'WARD'
    updated_name = 'UPDATED_WARD'
    
    print sc.convertInventoryValuesGoodTypes(name, updated_name)
    
    print "\nDATA FRAME OUTPUT\n"
    print sc.getARMDataFrame()
    
    print "\nDATA FRAME INPUT\n"
    sc.getARMDataFrameInfo()
    
    print "TEST TEST TEST\n"
    print sc.setFrameByFeatureList(my_customer_goods_test_headers)

    print "\nDATA FRAME OUTPUT\n"
    print sc.getARMDataFrame()
    
#    print "\nDATA FRAME INPUT\n"
#    sc.getARMDataFrameInfo()
    
    
if __name__ == "__main__":
    main()
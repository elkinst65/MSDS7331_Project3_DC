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
import sys

from ShoppingCart import ShoppingCart

debug_flag = False

class InventoryOfGoodsType (object):
    
    def __init__(self, df, customer_goods_headers):
        
        self.__df__ = df
        self.__customer_goods_headers = customer_goods_headers
        self.__inventory_good_type_dictionary = {}
        self.__inventory_goods_dictionary = {}
        
        self.createInventoryGoodTypeDictionary()
        self.createTotalItemsListedInGoodInventory()
        
        self.writeTotalListOfGoodsInInventoryFile()
    
    
    def getDataFrame(self):
        return self.__df__
        
    def getDataFrameInfo(self):
        return self.__df__.info()
        
    def getInventoryGoodTypeDictionary(self):
        return self.__inventory_good_type_dictionary
        
    def getUniqueInventoryGoodTypeItem(self, item):
        return self.__inventory_good_type_dictionary[item]
        
    def getCustomerGoodTypeHeaders(self):
        return self.__customer_goods_headers
    
    def getInventoryGoodTypeDictionaryLength(self):
        return len(self.__inventory_good_type_dictionary)
        
    '''
    Clean the input custom list.  That is, make sure that there are no 'nan'
    values in the list.   Firstly, the input custom list is sorted in ascending 
    order keeping only unique values in the list, then all 'nan' values are removed.  
    I saw this phenoma while I was unit testing this functionaility, and I noticed there were some 
    'nan' values in the list.  I Googled and found a solution via an online Stacks 
    OverFlow link, where a past user experienced and resolved the problem.   
    
    Reference the List Compression statement in the method below which removes all
    'NAN' or 'nan' values from the list.
    '''
    def clean_list(self, custom_list):
        
        my_list = sorted(set(custom_list))
        unique_list = list(OrderedDict(izip(my_list, repeat(None))))
    
        cleaned_list = [x for x in unique_list if str(x) != 'nan']
    
        return cleaned_list
        
   
        
    def createInventoryGoodTypeDictionary(self):
            
        number_of_items = 0
        self.__inventory_goods_dictionary = {}
        
        '''
        This code below can be rewritten in a more Pythonic way but this may not generalize the function below.
        I thought about using some hybrid form of a List Compression statement but that would make the 
        code quite complex and hard ot maintain.
        
        Build a table of contents type of glossary dictionary based on the main named topics.
        The inventory_good_type_dictionary dictionary is json based hybrid where the unique name
        is crossed reference to the name, input_list, output_list and list_length.
        '''
        for name in self.__customer_goods_headers:
           
            query_result = self.clean_list(sorted(self.__df__[name]))
            #print (query_result)
            
            number_of_items += len(query_result)
            
            if debug_flag is True:
                print "name\t{}".format(len(query_result))
 
            self.__inventory_good_type_dictionary[name] = { 'name': name, 
                                                            'input_list': sorted(query_result),
                                                            'output_list': None,
                                                            'list_length': len(query_result)}
            if debug_flag is True:
                print"\n\nITEMS IN STORE:\t{}".format(number_of_items)
            
            
    def createTotalItemsListedInGoodInventory(self):
        
        count = 0
        self.__total_items_good_inventory = {}
        new_list = False
        
        '''
        This code below can be rewritten in a more Pythonic way but this may not generalize the function below.
        I thought about using some hybrid form of a List Compression statement but that would make the 
        code quite complex and hard ot maintain.
        
        Builds an exhaustive list of all of the total items listed in the inventory.This time, the 
        TID (or unique item ID) is cross referenced by the item_id, description, category, type, input_list,
        output_list (==> dictionary json hybrid).   This code will create a new item id for every item
        listed in the inventory.  Later any of the items will be used by a customer in their shopping cart.
        '''
        for good_type in self.__customer_goods_headers:
            
            if debug_flag is True:
                print "NEW LIST NAME:\t\t{}".format(self.__inventory_good_type_dictionary[good_type]['name'])

            new_list = False
            

            for number in self.__inventory_good_type_dictionary[good_type]['input_list']:
                
                if new_list is False:
                    
                    if debug_flag is True:
                        print "INSIDE NEW_LIST FALSE TEST\n"
                        print "TABLE OF CONTENTS COUNT:\t{}".format(count)
                        print "NEW LIST LENGTH:\t".format(self.__inventory_good_type_dictionary[good_type]['list_length'])
                        print "\n"
            
                    new_created_list = list(range(count, (count + self.__inventory_good_type_dictionary[good_type]['list_length'])))
                    
                    self.__inventory_good_type_dictionary[good_type]['output_list'] = new_created_list
                    new_list = True
                
                self.__total_items_good_inventory[count] = { 'item_id': count,
                                                             'description': self.__inventory_good_type_dictionary[good_type]['name'] + "_" + str(number),
                                                             'category': self.__inventory_good_type_dictionary[good_type]['name'],
                                                             'number': number,
                                                             'type': self.__inventory_good_type_dictionary[good_type]['name'],
                                                             'input_list': self.__inventory_good_type_dictionary[good_type]['input_list'],
                                                             'output_list': new_created_list }
                                                     
                count += 1
                
                
        return count
        
    
    def getItemGoodInventory(self):
        return self.__total_items_good_inventory
     
    def getItemGoodInventoryLength(self):
        return len(self.__total_items_good_inventory)
        
    def getUniqueItemGoodInventory(self, count):
        return self.__total_items_good_inventory[count]
                
    
    def printEntireListOfGoodsInInventory(self):
        
        for index in self.__total_items_good_inventory:
            print "\n"
            print self.__total_items_good_inventory[index]
            
            
    def writeTotalListOfGoodsInInventoryFile(self):
        
        with open('data/dc_crime/DC_Crime_Goods_3.csv', 'w') as fp:
            
            for index in self.__total_items_good_inventory:
                
                fp.write('%d, %s, %s, %6.8f, %s\n' % (self.__total_items_good_inventory[index]['item_id'],
                                                      self.__total_items_good_inventory[index]['description'],
                                                      self.__total_items_good_inventory[index]['category'],
                                                      self.__total_items_good_inventory[index]['number'],
                                                      self.__total_items_good_inventory[index]['type'])) 
  
        
    
def main():
    
    # Read in the crime data from the CSV file
    df = pd.read_csv('data/dc_crime/DC_Crime_2015_Lab2_Weather.csv')
    
    my_customer_goods_headers = [ 'OFFENSE_Code',
                        'SHIFT_Code',
                        'METHOD_Code',
                        'CRIME_TYPE',
                        'DistrictID',
                        'PSA_ID',
                        'WARD',
                        'ANC',
                        'NEIGHBORHOOD_CLUSTER',
                        'CENSUS_TRACT',
                        'VOTING_PRECINCT',
                        'CCN',
                        'XBLOCK',
                        'YBLOCK',
                        'AGE',
                        'TIME_TO_REPORT',
                        'Latitude',
                        'Longitude',
                        'Max_Temp',
                        'Min_Temp',
                        'Max_Humidity',
                        'Min_Humidity',
                        'Max_Pressure',
                        'Min_Pressure',
                        'Precipitation']
                        
    my_customer_goods_test_headers = [ 'OFFENSE_Code',
                        'SHIFT_Code',
                        'METHOD_Code',
                        'CRIME_TYPE',
                        'DistrictID',
                        'PSA_ID',
                        'WARD',
                        'ANC']
                        #'NEIGHBORHOOD_CLUSTER',
                        #'CENSUS_TRACT',
                        #'VOTING_PRECINCT',
                        #'CCN']

    testObj = InventoryOfGoodsType(df, my_customer_goods_headers)
    
    
    print "DATAFRAME INFO"
    testObj.getDataFrame().info()

    if debug_flag is True:
        print "\nDATAFRAME INVENTORY GOODS DICTIONARY"
        print testObj.getInventoryGoodTypeDictionary()    
    
    print "\nNUMBER OF GOODS IN THE ACME INVENTORY:\t{}".format(testObj.getInventoryGoodTypeDictionaryLength()) 

    print "\nOFFENSE CODE"
    print testObj.getUniqueInventoryGoodTypeItem('OFFENSE_Code')
    
    print "\nCRIME_TYPE"
    print testObj.getUniqueInventoryGoodTypeItem('CRIME_TYPE')
    
    print "\nWARD"
    print testObj.getUniqueInventoryGoodTypeItem('WARD')
    
    if debug_flag is True:
        for name in my_customer_goods_test_headers:
            print "\nNAME:\t{}".format(name)
            print testObj.getUniqueInventoryGoodTypeItem(name)
        
    print "\n\n TOTAL LIST OF ITEMS IN THE INVENTORY \n"  
    print "{}".format(testObj.getInventoryGoodTypeDictionaryLength())
    
    print "\n\n GET UNIQUE ITEM FROM TOTAL INVENTORY LIST\n"
    
    print testObj.getUniqueItemGoodInventory(1)
    print "\n\n"
    
    print testObj.getUniqueItemGoodInventory(20)
    
    print "\n\n"
    print testObj.getUniqueItemGoodInventory(78799)
    
    
    print "\n********** PROCESSING DC CRIME SHOPPING CART TRANSACTIONS ***************************************"
    shoppingCart = ShoppingCart(df, testObj.getInventoryGoodTypeDictionary(), testObj.getCustomerGoodTypeHeaders())
    
    if debug_flag is True:
        print shoppingCart.getARMDataFrame()
    
    print "\n************* ARM Shopping DataFrame Info **************************"
    shoppingCart.getARMDataFrameInfo()
    
    print "\n************* ARM Shopping DataFrame Info **************************"
    shoppingCart.getARMShoppingCartDataFrameInfo()

    
if __name__ == "__main__":
    main()
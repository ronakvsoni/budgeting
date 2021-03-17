## General Info
This project was created by Alec DuBois and Ronak Soni for the purpose of learning Ruby and ActiveRecord. Mod1 Final Project at Flatiron School, presented on July 31, 2020.
Repo Link
https://github.com/afteralec/budgeting

## [This is a Demo Video](https://www.loom.com/share/69e6a26465da435a8f1785add2fb45f8) link of the Application

## Project Idea/Misson
Welcome to Budgeting App! Through our project you, the user, are able to create, choose, update and delete your excisting buddget,
firstely,the the app ask to create your profile, if you are excisting user then its ask for sign in and its recognize by email. secondely, you creates budgets more than one after sign in.Budget is connected through bank account wallet. so you can link you bank account.
Our project consists of 6 models,which is shown in the below image.
Transaction is our join classes, connecting Bankaccount and Expense

## Setup
To run this project, please run the following in your terminal:
```
$ cd ./budgeting    # be sure you're in this file directory
$ bundle install   # install necessary gems
$ ruby bin/run      # begin the program
```
You should see a welcome message...

## Domain

[![d5VdF4.md.jpg](https://iili.io/d5VdF4.md.jpg)](https://freeimage.host/i/d5VdF4)


User Story
1. Create - Create a user profile, budget, bank account, transaction category and expense
2. Read   - read created budget, bank wallet, expense, transaction 
3. Update - Update user profile, bank account, budget, transaction
4. Delete - Delete user profile, bank account, budget, transaction

Stretch Goals:
- linking bank account API

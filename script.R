library(tidyverse)
library(lubridate)
library(stringr)
library(stringi)


setwd("D:/_uni/analcup2023")

# Load data
business_units        <- read.csv(file = 'data/business_units.csv')
classification        <- read.csv(file = 'data/classification.csv')
customers             <- read.csv(file = 'data/customers_w_id.csv', colClasses=c("Sales_Order_ID"="character"))
sales_orders          <- read.csv(file = 'data/sales_orders_w_id.csv', colClasses=c("Sales_Order_ID"="character"))
sales_orders_header   <- read.csv(file = 'data/sales_orders_header.csv')
service_map           <- read.csv(file = 'data/service_map.csv')

#summary(classification)
#summary(customers)
#summary(sales_orders_header)
#summary(sales_orders)
#summary(business_units)
#summary(service_map)


# data to right format
classification <- transform(
  classification,
  Reseller = as.factor(Reseller)
)

customers <- transform(
  customers,
  Type = as.factor(Type),
  Sales_Order = toString(Sales_Order),
  Item_Position = toString(Item_Position)
)

# remove last 4 chars from Release_Date
sales_orders_header$Release_Date <- substr(sales_orders_header$Release_Date, 0, nchar(sales_orders_header$Release_Date)-4)
sales_orders_header <- transform(
  sales_orders_header,
  Sales_Organization = as.factor(Sales_Organization),
  Creation_Date = as_date(Creation_Date),
  Document_Type = as.factor(Document_Type),
  Release_Date = as_date(Release_Date)
)

sales_orders <- transform(
  sales_orders,
  Material_Code = as.factor(Material_Code),
  Cost_Center = as.factor(Cost_Center),
  Sales_Order = toString(Sales_Order),
  Item_Position = toString(Item_Position)
)



business_units <- transform(
  business_units,
  Business_Unit <- as.factor(Business_Unit)
)

# join classification with customers
join <- merge(classification, customers, by = "Customer_ID", suffix = c("CL", "CU"))
# join classification__customers with sales_orders
join <- merge(join, sales_orders, by = "Sales_Order_ID", suffix = c("CL", "SO"))
# join sales_orders__classification__customers with sales_orders_header
join <- merge(join, sales_orders_header, by = "Sales_Order")
# join sales_orders_header__sales_orders__classification__customers with business_units
join <- merge(join, business_units, by = "Cost_Center")


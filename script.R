library(tidyverse)
library(lubridate)
library(stringr)


setwd("D:/_uni/analcup2023")

# Load data
business_units        <- read.csv(file = 'data/business_units.csv')
classification        <- read.csv(file = 'data/classification.csv')
customers             <- read.csv(file = 'data/customers.csv')
sales_orders          <- read.csv(file = 'data/sales_orders.csv')
sales_orders_header   <- read.csv(file = 'data/sales_orders_header.csv')
service_map           <- read.csv(file = 'data/service_map.csv')

summary(classification)
summary(customers)
summary(sales_orders_header)
summary(sales_orders)
summary(business_units)
summary(service_map)


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
customers$Sales_Order_ID <- stri_join(customers$Sales_Order, customers$Item_Position)
print(stri_join("64755843740232540760231662788114647939966152591369452945472134175031264493121","0000"))

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
sales_orders$Sales_Order_ID <- stri_paste(sales_orders$Sales_Order, sales_orders$Item_Position)

business_units <- transform(
  business_units,
  Business_Unit <- as.factor(Business_Unit)
)

# join classification with customers
join <- merge(classification, customers, by = "Customer_ID")
# join classification__customers with sales_orders
join <- merge(join, sales_orders, by = "Sales_Order_ID")
# join sales_orders__classification__customers with sales_orders_header
join <- merge(join, sales_orders_header, by = "Sales_Order")
# join sales_orders_header__sales_orders__classification__customers with business_units
join <- merge(join, business_units, by = "Cost_Center")


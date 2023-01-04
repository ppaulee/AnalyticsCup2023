library(tidyverse)
library(lubridate)
library(stringr)
library(stringi)
library(dplyr)
library(caret)

set.seed(142038045)
setwd("C:/Users/joern/Code/AnalyticsCup2023")

# Load data
business_units        <- read.csv(file = 'data/business_units.csv')
classification        <- read.csv(file = 'data/classification.csv')
customers             <- read.csv(file = 'data/customers.csv')
sales_orders          <- read.csv(file = 'data/sales_orders.csv')
sales_orders_header   <- read.csv(file = 'data/sales_orders_header.csv')
service_map           <- read.csv(file = 'data/service_map.csv')

#summary(classification)
#summary(customers)
#summary(sales_orders_header)
#summary(sales_orders)
#summary(business_units)
#summary(service_map)



# data to right format
service_map <- transform(
  service_map,
  MATKL_service = as.factor(MATKL_service)
)


classification <- transform(
  classification,
  Reseller = as.logical(Reseller),
  Customer_ID = as.factor(Customer_ID)
)

customers <- transform(
  customers,
  Type = as.factor(Type),
  Sales_Order = as.character(Sales_Order),
  Item_Position = as.character(Item_Position),
  Customer_ID = as.factor(Customer_ID)
)

# remove last 4 chars from Release_Date
sales_orders_header$Release_Date <- substr(sales_orders_header$Release_Date, 0, nchar(sales_orders_header$Release_Date)-4)
sales_orders_header <- transform(
  sales_orders_header,
  Sales_Organization = as.factor(Sales_Organization),
  Creation_Date = as_date(Creation_Date),
  Document_Type = as.factor(Document_Type),
  Release_Date = as_date(Release_Date),
  Creator = as.factor(Creator),
  Delivery = as.factor(Delivery)
  
)

sales_orders <- transform(
  sales_orders,
  Material_Code = as.factor(Material_Code),
  Material_Class = as.factor(Material_Class),
  Cost_Center = as.factor(Cost_Center),
  Sales_Order = as.character(Sales_Order),
  Item_Position = as.character(Item_Position)
)



business_units <- transform(
  business_units,
  Business_Unit = as.factor(Business_Unit),
  Cost_Center = as.factor(Cost_Center),
  YHKOKRS = as.factor(YHKOKRS)
)

# join classification with customers
result <- merge(classification, customers, by = "Customer_ID")

customers_salesorders_count <-  customers['Sales_Order'] %>%
                                  group_by(Sales_Order) %>% 
                                  mutate(n = n())

customers_unique_salesorders <-  filter(customers_salesorders_count, n == 1) %>%  select(Sales_Order)

customers_unique_salesorders <- merge (customers_unique_salesorders, customers, by = "Sales_Order")

result_unique <- merge (customers_unique_salesorders, sales_orders, by = "Sales_Order", suffixes = c("","_y")) %>%  select(-Item_Position_y)

customers_shared_salesorders <-  filter(customers_salesorders_count, n > 1) %>%  select(Sales_Order)
#regain all attributes, especially the Item_Position which is needed.
extended_customers_shared_salesorders <- left_join(customers_shared_salesorders, customers, by = "Sales_Order")


customers_matching_itemPos <- merge(extended_customers_shared_salesorders, sales_orders, by = c("Sales_Order","Item_Position"))

unmatachable_orders <- anti_join(sales_orders, result_unique, by = "Sales_Order")

unmatachable_orders <- anti_join(unmatachable_orders, customers_matching_itemPos, by = c("Sales_Order","Item_Position"))

indices <- match(unmatachable_orders$Sales_Order, sales_orders$Sales_Order)
sales_orders[indices,"Item_Position"] <- 0

customers_matching_itemPos <- merge(extended_customers_shared_salesorders, sales_orders, by = c("Sales_Order","Item_Position"))


customers_no_matching_itemPos <- anti_join(extended_customers_shared_salesorders, sales_orders, by = c("Sales_Order","Item_Position"))

indi <- match(customers_no_matching_itemPos$Sales_Order, extended_customers_shared_salesorders$Sales_Order) %>% unique()
extended_customers_shared_salesorders[indi,"Item_Position"] <- "0"


result_shared_noPrevMatch <- merge(extended_customers_shared_salesorders, sales_orders, by = c("Sales_Order", "Item_Position"))


customers_end_result <- rbind(result_unique,customers_matching_itemPos)

# merge with all other data-frames
customers_end_result <- merge(customers_end_result, classification, by = "Customer_ID")

#switched the suffixes, as the line item cannot exceed the entire order price.

customers_end_result <- merge(customers_end_result, sales_orders_header, by = "Sales_Order", suffixes =  c("_header",""))

customers_end_result <- merge(customers_end_result, business_units, by = "Cost_Center")

customers_end_result$is_Service <- customers_end_result$Material_Class %in% service_map$MATKL_service

customers_end_result <- select(customers_end_result, -c("Sales_Order","Material_Class", "Item_Position", "YHKOKRS"))

training_data <- customers_end_result %>% filter(!is.na(Reseller)) %>% select(-"Test_set_id")

prediction_data <- customers_end_result %>% filter(is.na(Reseller))




#model
train_Index <- createDataPartition(training_data$Reseller, p = 0.7, list = FALSE)

train_data <- training_data[train_Index,]

test_data <- training_data[-train_Index,]

log_model <- glm(Reseller~.,data = train_data, family="binomial")
cor(training_data$Type, training_data$Cost_Center)



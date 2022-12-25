f = open("data/customers.csv")
f = f.read().split("\n")

f[0] = f[0] + ",Sales_Order_ID"
for i in range(1, len(f)-1):
    tmp = f[i].split(',')
    f[i] = f[i] + ",\"" + tmp[0] + tmp[1] + "\""
file = open("customers_w_id.csv", "w+")
file.write("\n".join(f))
file.close()


f = open("data/sales_orders.csv")
f = f.read().split("\n")

f[0] = f[0] + ",Sales_Order_ID"
for i in range(1, len(f)-1):
    tmp = f[i].split(',')
    f[i] = f[i] + ",\"" + tmp[0] + tmp[1].rjust(6, "0") + "\""
file = open("sales_orders_w_id.csv", "w+")
file.write("\n".join(f))
file.close()



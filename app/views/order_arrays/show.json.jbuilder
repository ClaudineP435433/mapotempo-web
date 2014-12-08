json.products do
  json.array! @order_array.customer.products, :id, :code, :name
end

json.columns do
  json.array! @order_array.days.times do |i|
    json.week_day l(@order_array.base_date + i, format: '%a')
    json.date l @order_array.base_date + i
  end
end

json.rows do
  json.array! @order_array.destinations_orders do |destination_orders|
    json.name destination_orders[0].destination.name
    json.comment destination_orders[0].destination.comment
    json.orders do
      json.array! destination_orders do |order|
        json.id order.id
        json.product_ids do
          json.array! order.products.collect(&:id)
        end
      end
    end
  end
end

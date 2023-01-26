select s.customer_id, order_date, product_name, price,
		case when order_date >= join_date then "Y" Else "N" end as member
			from sales s join menu m on s.product_id = m.product_id 
						left join members me on s.customer_id = me.customer_id
			order by customer_id, order_date, product_name;



with cte as (select s.customer_id, order_date, product_name, price,
		case when order_date >= join_date then "Y" Else "N" end as member
			from sales s join menu m on s.product_id = m.product_id 
						left join members me on s.customer_id = me.customer_id
			order by customer_id, order_date, product_name)
	select *, case when member = "N" then NULL else rank() over(partition by s.customer_id, member order by order_date) end as ranking
    from cte;
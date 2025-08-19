--E. Bonus Questions
--If Danny wants to expand his range of pizzas - how would this impact the existing data design? 
--Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
INSERT INTO PIZZA_NAMES VALUES (3, 'Supreme')

INSERT INTO PIZZA_RECIPES VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12')

SELECT * FROM PIZZA_NAMES
SELECT * FROM PIZZA_RECIPES
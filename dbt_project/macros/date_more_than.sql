{% test date_more_than_today(model, column_name) %}

    select *
    from {{ model }}
    where {{ column_name }} > now()

{% endtest %}
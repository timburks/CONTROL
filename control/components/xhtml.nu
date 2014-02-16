
(global XMLNS "http://www.w3.org/1999/xhtml")

(set &html (NuMarkupOperator operatorWithTag:"html" prefix:<<-END
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
END contents:(list xmlns:XMLNS)))

(set &xhtml-transitional (NuMarkupOperator operatorWithTag:"html" prefix:<<-END
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
END contents:(list xmlns:XMLNS)))

(set &xhtml-strict (NuMarkupOperator operatorWithTag:"html" prefix:<<-END
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
END contents:(list xmlns:XMLNS)))

(global && (NuMarkupOperator operatorWithTag:nil))

(send &div setEmpty:NO)
(send &a setEmpty:NO)
(send &script setEmpty:NO)
(send &textarea setEmpty:NO)


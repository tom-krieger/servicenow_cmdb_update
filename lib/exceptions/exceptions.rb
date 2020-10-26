##
# Exeption to throw if a ci is not found.
class CiNotFound < RuntimeError

end

##
# #Exception to throw if no keys are defined to request a CI from ServiceNOW.
class CiKeyNotDefined < RuntimeError

end
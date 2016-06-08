box.cfg({listen=3303})
box.schema.user.create('test', {password='t3st', if_not_exists=true})

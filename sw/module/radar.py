from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *

class Radar(Module,AutoCSR):
    def __init__(self,echo, done,trigger,PWM):

        self.clk=ClockSignal() 
        
        self.echo=echo
        self.done=done 
        self.trigger=trigger
        self.PWM=PWM 
        

        #Registros de estado
            #read
        self.distance=CSRStatus(16)
            #Write
        self.boton_cambiar_grados=CSRStorage(2)
        self.ultra=CSRStorage()

        self.specials +=Instance("radar",
            i_clk= self.clk,
            i_echo=self.echo,
            o_done=self.done, 
            o_trigger=self.trigger,
            o_PWM=self.PWM, 

            #read
            o_distance=self.distance.status,
            #Write
            i_boton_cambiar_grados=self.boton_cambiar_grados.storage,
            i_ultra=self.ultra.storage,

        )

 

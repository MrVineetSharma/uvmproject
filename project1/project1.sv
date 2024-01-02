                        // uvm tb for half adder
                        //      test4  when rst ==0 ,b ==1 ,sum ==~a ,cout == a;
`include"uvm_macros.svh"
import uvm_pkg::*;

// dut
module ha(input a,b,input rst,clk,output reg sum,cout);
initial
$display("i am in dut");
always@(posedge clk)
begin
if(rst)
  begin
  sum  <= 0;
  cout <= 0;
 end
else
begin
sum  <= a + b;
cout <= a * b;
end
$display("in dut a=%0d,b=%0d,sum=%0d,cout=%0d at time %0t",a,b,sum,cout,$time());
end
endmodule

//interface
interface intf(input logic clk);
//logic clk;
logic a;
logic b;
logic sum;
logic cout;
logic rst;
endinterface

//seq_item 
class ha_seq_item extends uvm_sequence;
rand logic a;
rand logic b;
rand logic rst;
logic sum;
logic cout;

`uvm_object_utils_begin(ha_seq_item)
  `uvm_field_int(a,UVM_DEFAULT);
  `uvm_field_int(b,UVM_DEFAULT);
  `uvm_field_int(sum,UVM_DEFAULT);
  `uvm_field_int(cout,UVM_DEFAULT);
 `uvm_field_int(rst,UVM_DEFAULT);
 `uvm_object_utils_end

function new(string path = "ha_seq_item");
super.new(path);
endfunction

endclass

//sequence
class ha_sequence extends uvm_sequence#(ha_seq_item);
ha_seq_item st;
  `uvm_object_utils(ha_sequence)

  function new(string path = "ha_sequence");
super.new(path);
endfunction

virtual task pre_body();
  `uvm_info(get_type_name(),$sformatf( "(ha_sequence) i am in pre_body at time %0t",$time()),UVM_NONE);
endtask

virtual task body();
st = ha_seq_item::type_id::create("st");
  repeat(10)
  begin
 wait_for_grant();
    st.randomize(st) with{st.rst ==0; st.b ==1;};
 send_request(st);
 wait_for_item_done();
    `uvm_info(get_type_name(),$sformatf("(ha_sequence) a=%0d,b=%0d,rst=%0d at time %0t",st.a,st.b,st.rst,$time()),UVM_NONE);
end
endtask

virtual task post_body();
  `uvm_info(get_type_name(),$sformatf( "(ha_sequence) i am in post_body at time %0t",$time()),UVM_NONE);
endtask

endclass

//sequencer
class sequencer extends uvm_sequencer#(ha_seq_item);
`uvm_component_utils(sequencer)

function new(string path = "sequencer" ,uvm_component parent = null);
super.new(path,parent);
endfunction

endclass

//driver
class driver extends uvm_driver#(ha_seq_item);
ha_seq_item dt;
virtual intf vif;
`uvm_component_utils(driver);

function new(string path = "driver",uvm_component parent = null);
super.new(path,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
`uvm_info(get_type_name(),"i am in build phase of driver",UVM_NONE);
  dt = ha_seq_item::type_id::create("dt");
   if(!uvm_config_db #(virtual intf)::get(null,"uvm_top","vif",vif))
      `uvm_error("DRV","Unable to access uvm_config_db");
 endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
`uvm_info(get_type_name(),"i am in connect phase of driver",UVM_NONE);
endfunction

task reset();
`uvm_info(get_type_name(),"resetting of driver",UVM_NONE);
  vif.rst <= 1;
  vif.a   <= 0;
  vif.b   <= 0;
  vif.sum <= 0;
  vif.cout <=0;
  repeat(1)@(posedge vif.clk);
  vif.rst <= 0;
endtask

virtual task run_phase(uvm_phase phase);
//phase.raise_objection(this);
`uvm_info(get_type_name(),"i am in  run phase of driver",UVM_NONE);
  reset();  
 forever
 begin
seq_item_port.get_next_item(dt);
vif.a <= dt.a;
vif.b <= dt.b;
vif.rst <= dt.rst;
seq_item_port.item_done(dt);
   `uvm_info(get_type_name(),$sformatf("(driver) value of a=%0d,b=%0d,rst=%0d at time=%0t",dt.a,dt.b,dt.rst,$time()),UVM_NONE);
 @(posedge vif.clk);
 @(posedge vif.clk);

end
//phase.drop_objection(this);
endtask
endclass

//monitor
class monitor extends uvm_monitor;
ha_seq_item mt;
virtual intf vif;
`uvm_component_utils(monitor);
uvm_analysis_port#(ha_seq_item)send;

function new(string path = "monitor",uvm_component parent = null);
super.new(path,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
`uvm_info(get_type_name(),"i am in build phase of monitor",UVM_NONE);
 mt = ha_seq_item::type_id::create("mt");
 send = new("send",this);
 if(!uvm_config_db#(virtual intf)::get(null,"uvm_top","vif",vif))
   `uvm_error(get_type_name(),"Unable to access uvm_config_db");
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
`uvm_info(get_type_name(),"i am in connect phase of monitor",UVM_NONE);
endfunction

virtual task  run_phase(uvm_phase phase);
//phase.raise_objection(this);
  `uvm_info(get_type_name(),"run phase of monitor",UVM_NONE);
  @(negedge vif.rst); 
  forever
    begin
   repeat(2)@(posedge vif.clk);
  mt.a = vif.a;
  mt.b = vif.b;
  mt.sum = vif.sum;
  mt.cout = vif.cout;
  mt.rst = vif.rst;

      `uvm_info(get_type_name(),$sformatf("(monitor)value of a=%0d,b=%0d,rst =%0d,sum=%0d,cout=%0d at time=%0t",mt.a,mt.b,mt.rst,mt.sum,mt.cout,$time()),UVM_NONE);
send.write(mt);
//phase.drop_objection(this);
end
endtask
endclass

//scoreboard
class scoreboard extends uvm_scoreboard;
ha_seq_item st;
`uvm_component_utils(scoreboard);
uvm_analysis_imp#(ha_seq_item,scoreboard)recv;

function new(string path = "scoreboard" ,uvm_component parent = null);
super.new(path,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
`uvm_info(get_type_name(),"i am in build phase of scoreboard",UVM_NONE);
st = ha_seq_item::type_id::create("st");
recv = new("recv",this);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
`uvm_info(get_type_name(),"i am in connect phase of scoreboard",UVM_NONE);
endfunction

virtual task run_phase(uvm_phase phase);
//phase.raise_objection(this);
  `uvm_info(get_type_name(),$sformatf("hello vineet i am in run phase of scoreboard at time %0t",$time()),UVM_NONE);
//phase.drop_objection(this);
endtask

virtual function void  write(ha_seq_item t);
st = t;
 //`uvm_info("sco","i am in scoreboard write function",UVM_NONE);

  `uvm_info(get_type_name(),$sformatf("(scoreboard)value of a=%0d,b=%0d,rst=%0d,sum=%0d,cout=%0d at time=%0t",t.a,t.b,t.rst,t.sum,t.cout,$time()),UVM_NONE);

  
  if((st.sum == ~st.a) && (st.cout == st.a))
      `uvm_info(get_type_name(),$sformatf("test pass with rst=%0d at time %0t",st.rst,$time()),UVM_NONE)
   else if ((st.rst==1) && (st.cout ==0) && (st.sum ==0))
     `uvm_info(get_type_name(),$sformatf("test pass with rst = %0d at time %0t",st.rst,$time()),UVM_NONE)     
     else                   
       `uvm_info(get_type_name(),$sformatf("test fail at time %0t",$time()),UVM_NONE);
  endfunction
endclass

//subscriber
class subscriber extends uvm_subscriber#(ha_seq_item);
ha_seq_item st;
`uvm_component_utils(subscriber);
uvm_analysis_imp#(ha_seq_item,subscriber)recv;

function new(string path ="subscriber",uvm_component parent = null);
super.new(path,parent);
cg = new();
endfunction

covergroup cg;
option.per_instance =1;
option.name = "vineet";
a:coverpoint st.a;
b:coverpoint st.b;
rst:coverpoint st.rst;
sum:coverpoint st.sum;
cout:coverpoint st.cout;
  
endgroup

virtual function void write(ha_seq_item t);
st = t;
cg.sample();
//`uvm_info(get_type_name(),"i am in subscriber write function",UVM_NONE);
//`uvm_info(get_type_name(),$sformatf("(subscriber)value of a=%0d,b=%0d,sum=%0d,cout=%0d at time=%0t",st.a,st.b,st.sum,st.cout,$time()),UVM_NONE);
`uvm_info(get_type_name(),$sformatf("(subscriber)value of coverage is =%0f at time=%0t",cg.get_coverage(),$time()),UVM_NONE);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
`uvm_info(get_type_name(),"i am in build phase of subscriber",UVM_NONE);
st = ha_seq_item::type_id::create("st");
recv = new("recv",this);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
`uvm_info(get_type_name(),"i am in connect phase of subscriber",UVM_NONE);
endfunction

virtual task  run_phase(uvm_phase phase);
//phase.raise_objection(this);
`uvm_info(get_type_name(),"i am in run phase of subscriber",UVM_NONE);
//phase.drop_objection(this);
endtask
endclass

//agent

class agent extends uvm_agent;
driver drv;
monitor mon;
sequencer seqr;
`uvm_component_utils(agent);
function new(string path = "agent" ,uvm_component parent = null);
super.new(path,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
`uvm_info(get_type_name(),"i am in build phase of agent",UVM_NONE);
 drv= driver::type_id::create("drv",this);
 mon = monitor::type_id::create("mon",this);
 seqr = sequencer::type_id::create("seqr",this);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
`uvm_info(get_type_name(),"i am in connect phase of agent",UVM_NONE);
drv.seq_item_port.connect(seqr.seq_item_export);
endfunction

virtual task run_phase(uvm_phase phase);
//phase.raise_objection(this);
`uvm_info(get_type_name(),"i am in run phase of agent",UVM_NONE);
//phase.drop_objection(this);
endtask
endclass

//environment
class  env extends uvm_env;
agent ag;
scoreboard sco;
subscriber scb;
`uvm_component_utils(env);

function new(string path = "env" ,uvm_component parent = null);
super.new(path,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
`uvm_info(get_type_name(),"i am in build phase of environmemt",UVM_NONE);
 ag= agent::type_id::create("ag",this);
 sco= scoreboard::type_id::create("sco",this);
 scb= subscriber::type_id::create("scb",this);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
`uvm_info(get_type_name(),"i am in connect phase of environment",UVM_NONE);
 ag.mon.send.connect(sco.recv);
 ag.mon.send.connect(scb.recv);
endfunction

virtual task  run_phase(uvm_phase phase);
//phase.raise_objection(this);
`uvm_info(get_type_name(),"i am in run phase of env",UVM_NONE);
//phase.drop_objection(this);
endtask
endclass

//base_test
class  base_test extends uvm_test;
env en;
`uvm_component_utils(base_test);

function new(string path = "base_test",uvm_component parent = null);
super.new(path,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
`uvm_info(get_type_name(),"i am in build phase of base_test",UVM_NONE);
 en = env::type_id::create("env",this);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
`uvm_info(get_type_name(),"i am in connect phase of base_test",UVM_NONE);
endfunction

virtual task  run_phase(uvm_phase phase);
//phase.raise_objection(this);
`uvm_info(get_type_name(),"i am in run phase of base_test",UVM_NONE);
//phase.drop_objection(this);
endtask
endclass

//test1
class  test4 extends base_test;
ha_sequence seq;
  `uvm_component_utils(test4);

  function new(string path = "test4" ,uvm_component parent = null);
super.new(path,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
  `uvm_info(get_type_name(),"i am in  build phase of test4",UVM_NONE);
  seq = ha_sequence::type_id::create("seq");
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
  `uvm_info(get_type_name(),"i am in  connect phase of test4",UVM_NONE);
endfunction

virtual task run_phase(uvm_phase phase);
phase.raise_objection(this);
  `uvm_info(get_type_name(),"i am in  run phase of test4",UVM_NONE);
seq.start(en.ag.seqr);
 #5;
phase.drop_objection(this);
endtask
endclass

//assertion module
module asr(input wire aa,ab,aclk,arst,asum,acout);
initial
$display("i am in asr module for assertion");

  A1:  assert property(@(posedge aclk) (aa))
          $info("A1 assertion pass at time %0t",$time());
       else
          $error("A1 assertion fail at time %0t",$time());

endmodule

//bind module
module asrbind();
bind ha asr i_haasr(
.aa(a),
.ab(b),
.aclk(clk),
.asum(sum),
.acout(cout),
.arst(rst)
);
endmodule
//module tbtop
module tb_top();
logic clk = 0;
always #1 clk = ~clk;
 intf aif(clk);

ha dut(.a(aif.a),
       .b(aif.b),
       .clk(aif.clk),
       .sum(aif.sum),
       .cout(aif.cout),
       .rst(aif.rst)
       );
initial
begin
uvm_config_db#(virtual intf)::set(null,"uvm_top","vif",aif);
  run_test("test4");
end

initial begin
$dumpfile("dump.vcd");
$dumpvars;
end

endmodule





import numpy as np
import torch
dtype = torch.double
device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")

class Linear:
	def __init__(self, in_neurons, out_neurons):
		self.out_neurons = out_neurons
		self.in_neurons = in_neurons

		self.output = None # batch_size X out_neurons
		self.W = torch.randn(out_neurons, in_neurons, dtype=dtype) # out_neurons X in_neurons
		self.B = torch.randn(out_neurons, 1, dtype=dtype) # out_neurons X 1
		self.gradW = torch.zeros(out_neurons, in_neurons, dtype=dtype) # out_neurons X in_neurons
		self.gradB = torch.zeros(out_neurons, 1, dtype=dtype) # out_neurons X 1
		self.gradInput = None # batch_size X in_neurons
	
	def forward(self, input):
		self.output = input.mm(self.W.transpose(0,1)).add(self.B)

	def backward(self, input, gradOutput):
		self.gradInput = gradOutput.mm(self.W)
		self.gradB = gradOutput.sum(dim = 0)
		self.gradW = gradOutput.transpose(0,1).mm(input)
		return self.gradInput

	def clearGradParam(self):
		self.gradW = torch.zeros(out_neurons, in_neurons) # out_neurons X in_neurons
		self.gradB = torch.zeros(out_neurons, 1) # out_neurons X 1

	def dispGradParam(self):
		print("Linear Layer")
		print(self.W)
		print(self.B)

	def updateParam(self, learningRate):
		self.W -= learningRate*gradW
		self.B -= learningRate*gradB

package su.nsk.iae.edtl.generator

import org.eclipse.xtext.generator.IGenerator2
import su.nsk.iae.edtl.edtl.Model

interface IEdtlGenerator extends IGenerator2 {
	def void setModel(Model model)	
}
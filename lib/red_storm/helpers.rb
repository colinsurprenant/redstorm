# convience classes to change java method signature to ruby
module RedStorm
	module TransactionalEmitter

	  def emitBatch(tx, coordinatorMeta, collector)
	    emit_batch(tx, coordinatorMeta, collector)
	  end 

	  def cleanupBefore(txid)
	    cleanup_before(txid) if respond_to?(:cleanup_before)
	  end

	end

	module TransactionalCoordinator

	  def initializeTransaction(txid, prevMetadata)
	    initialize_transaction(txid, prevMetadata) if respond_to?(:initialize_transaction)
	  end

	  def isReady
	    respond_to?(:ready?) ? ready? : true
	  end

	end
end
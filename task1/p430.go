package task1

type Node struct {
	Val   int
	Prev  *Node
	Next  *Node
	Child *Node
}

// p430
func flatten(root *Node) *Node {
	head, _ := _flatten(root)
	return head
}

func _flatten(root *Node) (*Node, *Node) {
	if root == nil {
		return nil, nil
	}
	head := root
	current := root
	for current.Next != nil {
		if current.Child != nil {
			childHead, childTail := _flatten(current.Child)
			current.Child = nil
			tempNext := current.Next
			current.Next, childHead.Prev = childHead, current
			childTail.Next, tempNext.Prev = tempNext, childTail
			current = tempNext
		} else {
			current = current.Next
		}
	}
	if current.Child != nil {
		childHead, childTail := _flatten(current.Child)
		current.Child = nil
		current.Next, childHead.Prev = childHead, current
		current = childTail
	}
	return head, current
}

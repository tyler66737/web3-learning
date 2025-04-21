package task1

type ListNode struct {
	Val  int
	Next *ListNode
}

func findNextNode(l1 *ListNode, l2 *ListNode) int {
	if l1 != nil && l2 != nil {
		if l1.Val < l2.Val {
			return 1
		} else {
			return 2
		}
	} else if l1 != nil {
		return 1
	} else if l2 != nil {
		return 2
	} else {
		return 0
	}
}

// p21: merge two sorted linked lists
func mergeTwoLists(l1 *ListNode, l2 *ListNode) *ListNode {
	var head, tail *ListNode
	for {
		p := findNextNode(l1, l2)
		var current *ListNode
		if p == 1 {
			current, l1 = l1, l1.Next
		} else if p == 2 {
			current, l2 = l2, l2.Next
		} else {
			break
		}
		if head == nil {
			head = current
			tail = current
		} else {
			tail.Next, tail = current, current
		}
	}
	return head
}

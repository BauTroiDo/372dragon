#include "behaviortree_cpp/behavior_tree.h"
#include "behaviortree_cpp/bt_factory.h"
#include "behaviortree_cpp/blackboard.h"
#include "behaviortree_cpp/xml_parsing.h"
#include "sol.hpp"

extern "C"
{
	int luaopen_lbt(lua_State *L)
	{
		sol::state_view state_view(L);
		auto bt_lib = state_view.create_table();
		bt_lib.set_function("writeTreeNodesModelXML", &BT::writeTreeNodesModelXML);
		bt_lib.new_usertype<BT::BehaviorTreeFactory>(
			"BehaviorTreeFactory", "new",
			sol::initializers([](BT::BehaviorTreeFactory &uninitialized_memory)
							  { return new (&uninitialized_memory) BT::BehaviorTreeFactory(); }),
			"registerBehaviorTreeFromText", &BT::BehaviorTreeFactory::registerBehaviorTreeFromText,
			"createTree", sol::overload([](BT::BehaviorTreeFactory *factory, const std::string& tree_name){
				return factory->createTree(tree_name);
			}),
			"registerSimpleCondition", sol::overload([](BT::BehaviorTreeFactory *factory, const std::string &ID, sol::table table, sol::function func){
				std::function<BT::NodeStatus(BT::TreeNode&)> tickFunctor = [table, ID, func](BT::TreeNode& node) -> BT::NodeStatus {
    			// 将 Lua 表和 Lua 函数作为参数传递给回调函数
				printf("ID = %s\n", ID.c_str());
    			sol::protected_function_result result = func(table, node.status());
    			if (!result.valid()) {
        			sol::error err = result;
    				printf("Lua error: %s\n", err.what());
        			return BT::NodeStatus::FAILURE;
    			}
    			return result;
				};
				return factory->registerSimpleCondition(ID, tickFunctor); 
			}),
			"registerSimpleAction", sol::overload([](BT::BehaviorTreeFactory *factory, const std::string &ID, sol::table table, sol::function func){
				std::function<BT::NodeStatus(BT::TreeNode&)> tickFunctor = [table, ID, func](BT::TreeNode& node) -> BT::NodeStatus {
    			// 将 Lua 表和 Lua 函数作为参数传递给回调函数
				printf("ID = %s\n", ID.c_str());
    			sol::protected_function_result result = func(table, node.status());
    			if (!result.valid()) {
        			sol::error err = result;
    				printf("Lua error: %s\n", err.what());
        			return BT::NodeStatus::FAILURE;
    			}
    			return result;
				};
				return factory->registerSimpleAction(ID, tickFunctor); 
			})	
			);
		bt_lib.new_usertype<BT::Tree>(
			"Tree", "new",
			sol::initializers([](BT::Tree &uninitialized_memory)
							  { return new (&uninitialized_memory) BT::Tree(); }),
			"tickWhileRunning",  sol::overload([](BT::Tree *tree){
				return tree->tickWhileRunning();
			}));

		bt_lib.new_enum("NodeStatus",
             "IDLE", BT::NodeStatus::IDLE,
             "RUNNING", BT::NodeStatus::RUNNING,
             "SUCCESS", BT::NodeStatus::SUCCESS,
             "FAILURE", BT::NodeStatus::FAILURE,
             "SKIPPED", BT::NodeStatus::SKIPPED
		);
		return bt_lib.push();
	}
}
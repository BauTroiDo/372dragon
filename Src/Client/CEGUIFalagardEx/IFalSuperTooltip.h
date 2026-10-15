
namespace CEGUI
{

	class IFalagardSuperTooltip
	{
	public:
		/*!
		\brief
			Recaculate all subwindow
		*/
		virtual void			resizeSelf(void) = 0;
        virtual bool scrollContent(float delta) = 0;

	};

}

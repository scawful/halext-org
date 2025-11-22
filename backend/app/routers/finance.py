from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app import crud, models, schemas, auth
from app.dependencies import get_db

router = APIRouter()

@router.get("/finance/accounts", response_model=List[schemas.FinanceAccount])
def list_finance_accounts(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.get_finance_accounts(db, current_user.id)


@router.post("/finance/accounts", response_model=schemas.FinanceAccount, status_code=status.HTTP_201_CREATED)
def create_finance_account(
    payload: schemas.FinanceAccountCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.create_finance_account(db, current_user.id, payload)


@router.get("/finance/accounts/{account_id}", response_model=schemas.FinanceAccount)
def get_finance_account(
    account_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    account = crud.get_finance_account(db, current_user.id, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    return account


@router.put("/finance/accounts/{account_id}", response_model=schemas.FinanceAccount)
def update_finance_account(
    account_id: int,
    payload: schemas.FinanceAccountUpdate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    account = crud.get_finance_account(db, current_user.id, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    return crud.update_finance_account(db, account, payload)


@router.delete("/finance/accounts/{account_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_finance_account(
    account_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    account = crud.get_finance_account(db, current_user.id, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    crud.delete_finance_account(db, account)


@router.post("/finance/accounts/{account_id}/sync", response_model=schemas.FinanceAccount)
def sync_finance_account(
    account_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    account = crud.get_finance_account(db, current_user.id, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    account.last_synced = datetime.utcnow()
    db.add(account)
    db.commit()
    db.refresh(account)
    return account


@router.post("/finance/plaid/link-token")
def create_plaid_link_token(
    current_user: models.User = Depends(auth.get_current_active_user),
):
    """
    Placeholder Plaid link token endpoint to satisfy iOS client.
    Returns a mock link_token and expiration.
    """
    return {
        "link_token": f"mock-link-token-{current_user.id}",
        "expiration": datetime.utcnow().isoformat() + "Z",
    }


@router.post("/finance/plaid/exchange-token")
def exchange_plaid_public_token(
    public_token: str = "",
    current_user: models.User = Depends(auth.get_current_active_user),
):
    """
    Placeholder exchange endpoint; in production this would create an access token.
    """
    if not public_token:
        raise HTTPException(status_code=400, detail="public_token is required")
    return {
        "status": "linked",
        "public_token": public_token,
        "message": "Plaid integration is mocked in this environment.",
    }


@router.get("/finance/transactions", response_model=List[schemas.FinanceTransaction])
def list_finance_transactions(
    account_id: Optional[int] = None,
    limit: int = 50,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.list_finance_transactions(db, current_user.id, account_id=account_id, limit=limit)


@router.post("/finance/transactions", response_model=schemas.FinanceTransaction, status_code=status.HTTP_201_CREATED)
def create_finance_transaction(
    payload: schemas.FinanceTransactionCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.create_finance_transaction(db, current_user.id, payload)


@router.get("/finance/budgets", response_model=List[schemas.FinanceBudget])
def list_finance_budgets(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.get_finance_budgets(db, current_user.id)


@router.post("/finance/budgets", response_model=schemas.FinanceBudget, status_code=status.HTTP_201_CREATED)
def create_finance_budget(
    payload: schemas.FinanceBudgetCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.create_finance_budget(db, current_user.id, payload)


@router.patch("/finance/budgets/{budget_id}", response_model=schemas.FinanceBudget)
def update_finance_budget(
    budget_id: int,
    payload: schemas.FinanceBudgetUpdate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    budget = crud.get_finance_budget(db, current_user.id, budget_id)
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    return crud.update_finance_budget(db, budget, payload)


@router.delete("/finance/budgets/{budget_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_finance_budget(
    budget_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    budget = crud.get_finance_budget(db, current_user.id, budget_id)
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    crud.delete_finance_budget(db, budget)


@router.get("/finance/summary", response_model=schemas.FinanceSummary)
def finance_summary(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    return crud.get_finance_summary(db, current_user.id)


# Budget Progress Endpoints

@router.get("/finance/budgets/progress", response_model=List[schemas.BudgetProgress])
def get_budget_progress(
    period: Optional[str] = None,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Get budget progress for all active budgets.
    Calculates spent amounts from transactions within the budget period.

    - **period**: Optional override for budget period (weekly, monthly, quarterly, yearly)
    """
    return crud.get_budget_progress(db, current_user.id, period=period)


@router.get("/finance/budgets/{budget_id}/progress", response_model=schemas.BudgetProgress)
def get_single_budget_progress(
    budget_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Get progress for a specific budget.
    """
    progress_list = crud.get_budget_progress(db, current_user.id, budget_id=budget_id)
    if not progress_list:
        raise HTTPException(status_code=404, detail="Budget not found")
    return progress_list[0]


@router.get("/finance/budgets/progress/summary", response_model=schemas.BudgetProgressSummary)
def get_budget_progress_summary(
    period: str = "monthly",
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Get aggregated budget progress summary.
    Includes totals across all budgets and alert counts.

    - **period**: Budget period to summarize (weekly, monthly, quarterly, yearly)
    """
    return crud.get_budget_progress_summary(db, current_user.id, period=period)


@router.post("/finance/budgets/{budget_id}/sync", response_model=schemas.FinanceBudget)
def sync_budget_spent(
    budget_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Recalculate and sync the spent_amount for a budget from transactions.
    """
    budget = crud.update_budget_spent_amount(db, current_user.id, budget_id)
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    return budget


@router.post("/finance/budgets/sync-all", response_model=List[schemas.FinanceBudget])
def sync_all_budgets_spent(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db),
):
    """
    Recalculate and sync spent_amount for all active budgets.
    """
    return crud.sync_all_budget_spent_amounts(db, current_user.id)

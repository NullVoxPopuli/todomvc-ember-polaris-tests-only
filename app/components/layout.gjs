import { fn, uniqueId } from '@ember/helper';
import { on } from '@ember/modifier';
import { isBlank } from '@ember/utils';

import title from 'ember-page-title/helpers/page-title';
import { cell } from 'ember-resources';
import { TrackedMap, TrackedObject } from 'tracked-built-ins';

function hasTodos(todos) {
  return todos.length > 0;
}

export const activeList = cell('All');
export const canToggleAll = cell(true);
export const isEditing = cell(false);

const isViewingAll = () => activeList.current === 'All';
const isViewingActive = () => activeList.current === 'Active';
const isViewingCompleted = () => activeList.current === 'Completed';
const showAll = () => activeList.current = 'All'; 
const showActive = () => activeList.current = 'Active';
const showCompleted = () => activeList.current = 'Completed';

class Repo {
	data = null;

	load = () => {this.data = load()};

	get all() {
		return [...this.data.values()];
	}

	get completed() {
		return this.all.filter((todo) => todo.completed);
	}

	get active() {
		return this.all.filter((todo) => !todo.completed);
	}

	get remaining() {
		return this.active;
	}

  get areAllCompleted() {
    return this.completed.length === this.all.length;
  }

	add = (attrs) => {
		let newId = uniqueId();

		this.data.set(newId, new TrackedObject({ ...attrs, id: newId }));
		this.persist();
	};

	delete = (todo) => {
		this.data.delete(todo.id);
		this.persist();
	};

	clearCompleted = () => this.completed.forEach(this.delete);
	persist = () => save(this.data);
}


export const repo = new Repo();

const TodoApp = <template>
  {{repo.load}}

  <section class="todoapp">
    <header class="header">
      <h1>todos</h1>

      <Create />
    </header>

    {{#if (isViewingAll)}}
      {{title "All"}}

      <TodoList @todos={{repo.all}} />
    {{else if (isViewingActive)}}
      {{title "Active"}}

      <TodoList @todos={{repo.active}} />
    {{else if (isViewingCompleted)}}
      {{title "Completed"}}

      <TodoList @todos={{repo.completed}} />
    {{/if}}

    {{#if (hasTodos repo.all)}}
      <Footer />
    {{/if}}
  </section>
</template>;

export default TodoApp;

function load() {
	let list = JSON.parse(window.localStorage.getItem('todos') || '[]');

	return list.reduce((indexed, todo) => {
		indexed.set(todo.id, new TrackedObject(todo));

		return indexed;
	}, new TrackedMap());
}

function save(indexedData) {
	let data = [...indexedData.values()];

	window.localStorage.setItem('todos', JSON.stringify(data));
}

function createTodo(event) {
    let { keyCode, target } = event;
    let value = target.value.trim();

    if (keyCode === 13 && !isBlank(value)) {
				repo.add({ title: value, completed: false });
				target.value = '';
    }	
}


const Create = <template>
  <input
    class="new-todo"
    {{on 'keydown' createTodo}}
    aria-label="What needs to be done?"
    placeholder="What needs to be done?"
    autofocus
  >
</template>;

function itemLabel(count) {
  if (count === 0 || count > 1) {
    return 'items';
  }

  return 'item';
}

const Footer = <template>
  <footer class="footer">
    <span class="todo-count">
      <strong>{{repo.remaining.length}}</strong>
     {{itemLabel repo.remaining.length}} left
    </span>

    <ul class="filters">
      <li>
        <a href="#" class={{if (isViewingAll) 'selected'}} {{on 'click' showAll}}>
          All
        </a>
      </li>
      <li>
        <a href="#" class={{if (isViewingActive) 'selected'}} {{on 'click' showActive}}>
          Active
        </a>
      </li>
      <li>
        <a href="#" class={{if (isViewingCompleted) 'selected'}} {{on 'click' showCompleted}}>
          Completed
        </a>
      </li>
    </ul>

    {{#if repo.completed.length}}
      <button class="clear-completed" type="button" {{on "click" repo.clearCompleted}}>
        Clear completed
      </button>
    {{/if}}
  </footer>
</template>;


function toggleAll(todos) {
  let areAllCompleted = repo.areAllCompleted;

  todos.forEach(todo => todo.completed = !areAllCompleted);
  repo.persist();
}

const TodoList = <template>
  <section class="main">
    {{#if @todos.length}}
      {{#if canToggleAll.current}}
        <input
          id="toggle-all"
          class="toggle-all"
          type="checkbox"
          checked={{repo.areAllCompleted}}
          {{on 'change' (fn toggleAll @todos)}}
        >
        <label for="toggle-all">Mark all as complete</label>
      {{/if}}
      <ul class="todo-list">
        {{#each @todos as |todo|}}
          <TodoItem @todo={{todo}} />
        {{/each}}
      </ul>
    {{/if}}
  </section>
</template>;


function toggleCompleted(todo, event) {
    todo.completed = event.target.checked;
    repo.persist();
}

function startEditing(event) {
  canToggleAll.current = false;
  isEditing.current = true;

  event.target.closest('li')?.querySelector('input.edit').focus();
}

function doneEditing(todo, event) {
  if (!isEditing.current) { return; }

  let todoTitle = event.target.value.trim();

  if (isBlank(todoTitle)) {
    repo.delete(todo);
  } else {
    todo.title = todoTitle;
    isEditing.current = false;
    canToggleAll.current = true;
  }
}

function itemKeydown(event) {
  if (event.keyCode === 13) {
    event.target.blur();
  } else if (event.keyCode === 27) {
    isEditing.current = false;
  }
}

const TodoItem = <template>
  <li class="{{if @todo.completed 'completed'}} {{if isEditing.current 'editing'}}">
    <div class="view">
      <input
        class="toggle"
        type="checkbox"
        aria-label="Toggle the completion state of this todo"
        checked={{@todo.completed}}
        {{on 'change' (fn toggleCompleted @todo)}}
      >
      <label {{on 'dblclick' startEditing}}>{{@todo.title}}</label>
      <button
        class="destroy"
        {{on 'click' (fn repo.delete @todo)}}
        type="button"
        aria-label="Delete this todo"></button>
    </div>
    <input
      class="edit"
      value={{@todo.title}}
      {{on 'blur' (fn doneEditing @todo)}}
      {{on 'keydown' itemKeydown}}
      autofocus
    >
  </li>
</template>;
